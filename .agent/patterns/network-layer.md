# Pattern: Network Layer

**Apply when:** Any task involves API calls, HTTP requests, or external data fetching.
Run this pattern before Code Gen writes any Repository or Service file that touches the network.

---

## Standard Architecture

```
View → ViewModel → ServiceProtocol → Service → RepositoryProtocol → Repository → NetworkClient
```

**Rules:**
- ViewModels never call NetworkClient directly — always through a Service
- Repositories own HTTP — they never contain business logic
- Services own business logic — they never build URLs or parse HTTP responses
- Always inject dependencies via protocol — never instantiate concrete types inside a class

---

## NetworkClient

### Protocol

```swift
// Core/Network/NetworkClientProtocol.swift
protocol NetworkClientProtocol: Sendable {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func requestData(_ endpoint: Endpoint) async throws -> Data
}
```

### Endpoint

```swift
// Core/Network/Endpoint.swift
struct Endpoint: Sendable {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]
    let body: (any Encodable & Sendable)?
    let headers: [String: String]

    init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        body: (any Encodable & Sendable)? = nil,
        headers: [String: String] = [:]
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.body = body
        self.headers = headers
    }
}

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
```

### Concrete Implementation

```swift
// Core/Network/NetworkClient.swift
final class NetworkClient: NetworkClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await requestData(endpoint)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AppNetworkError.decodingFailed(underlying: error)
        }
    }

    func requestData(_ endpoint: Endpoint) async throws -> Data {
        let urlRequest = try buildRequest(endpoint)
        let (data, response) = try await session.data(for: urlRequest)
        try validate(response: response, data: data)
        return data
    }

    // MARK: - Private

    private func buildRequest(_ endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path),
                                             resolvingAgainstBaseURL: true) else {
            throw AppNetworkError.invalidURL
        }
        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }
        guard let url = components.url else { throw AppNetworkError.invalidURL }

        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        endpoint.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        if let body = endpoint.body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        return request
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw AppNetworkError.invalidResponse
        }
        switch http.statusCode {
        case 200...299: return
        case 401:       throw AppNetworkError.unauthorized
        case 404:       throw AppNetworkError.notFound
        case 422:       throw AppNetworkError.unprocessableEntity(data: data)
        case 500...599: throw AppNetworkError.serverError(statusCode: http.statusCode)
        default:        throw AppNetworkError.httpError(statusCode: http.statusCode, data: data)
        }
    }
}
```

---

## Retry Logic

Add retry for transient failures only (timeout, no connection). Never retry 4xx.

```swift
// Core/Network/NetworkClient+Retry.swift
extension NetworkClient {
    func requestWithRetry<T: Decodable>(
        _ endpoint: Endpoint,
        maxAttempts: Int = 3,
        delay: Duration = .seconds(1)
    ) async throws -> T {
        var lastError: Error?
        for attempt in 1...maxAttempts {
            do {
                return try await request(endpoint)
            } catch AppNetworkError.serverError, AppNetworkError.invalidResponse {
                lastError = lastError
                if attempt < maxAttempts {
                    try await Task.sleep(for: delay * Double(attempt)) // exponential backoff
                }
            } catch {
                throw error // non-retriable — propagate immediately
            }
        }
        throw lastError ?? AppNetworkError.unknown
    }
}
```

---

## Mock for Tests

Every Repository test MUST use MockNetworkClient — never hit a real server.

```swift
// Tests/Mocks/MockNetworkClient.swift
final class MockNetworkClient: NetworkClientProtocol {
    var stubbedResult: (any Sendable)?
    var stubbedError: Error?
    private(set) var requestedEndpoints: [Endpoint] = []

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        requestedEndpoints.append(endpoint)
        if let error = stubbedError { throw error }
        guard let result = stubbedResult as? T else {
            throw AppNetworkError.decodingFailed(underlying: MockError.typeMismatch)
        }
        return result
    }

    func requestData(_ endpoint: Endpoint) async throws -> Data {
        requestedEndpoints.append(endpoint)
        if let error = stubbedError { throw error }
        return stubbedResult as? Data ?? Data()
    }
}

private enum MockError: Error { case typeMismatch }
```

---

## Code Gen Rules

When generating any Repository or Service file:

1. **Add to task file list:**
   - `Core/Network/NetworkClientProtocol.swift`
   - `Core/Network/NetworkClient.swift`
   - `Core/Network/Endpoint.swift`
   - `Core/Network/AppNetworkError.swift`
   - `Tests/Mocks/MockNetworkClient.swift`

2. **Add to `project.yml` packages section** if a third-party HTTP client is needed:
   ```yaml
   packages:
     # No external HTTP library needed — URLSession is sufficient
   ```

3. **Repository layer rules:**
   - Constructor-inject `NetworkClientProtocol`
   - Build `Endpoint` values as private static properties or functions
   - Map `AppNetworkError` to domain errors in the repository

4. **No networking in ViewModels** — if a ViewModel has `import Foundation` AND `URLSession`/`URLRequest` → BLOCKER

---

## Self-check (per file)

- [ ] Repository injects `NetworkClientProtocol`, not `NetworkClient`
- [ ] No `URLSession.shared` directly in Repository or ViewModel
- [ ] `Endpoint` used for all requests — no raw URL string construction
- [ ] All HTTP errors mapped to `AppNetworkError`
- [ ] Mock provided in `Tests/Mocks/`
- [ ] Retry used only for server/connection errors, not 4xx
