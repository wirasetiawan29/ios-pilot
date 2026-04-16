# Pattern: Persistence (SwiftData)

**Apply when:** Spec involves offline support, local cache, user preferences beyond UserDefaults,
or any data that must survive app restart.

iOS 17+ target → use **SwiftData**. CoreData only if migrating an existing project.

---

## Architecture

```
ViewModel → ServiceProtocol → Service → RepositoryProtocol
                                            → SwiftDataRepository  (production)
                                            → InMemoryRepository   (tests)
```

SwiftData is an implementation detail of the Repository. ViewModels never import SwiftData.

---

## Model Definition

```swift
// Core/Persistence/Models/<Name>Entity.swift
import SwiftData

@Model
final class OrderEntity {
    @Attribute(.unique) var id: String
    var status: String
    var totalAmount: Double
    var createdAt: Date
    var updatedAt: Date

    init(id: String, status: String, totalAmount: Double, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.status = status
        self.totalAmount = totalAmount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

**Rules:**
- `@Model` class, not struct (SwiftData requirement)
- `@Attribute(.unique)` on ID fields
- Separate `Entity` (persistence) from domain `Model` (business logic)
- No business logic in `@Model` classes — they are data containers only

---

## Domain ↔ Entity Mapping

```swift
// Core/Persistence/Models/OrderEntity+Mapping.swift
extension OrderEntity {
    convenience init(from order: Order) {
        self.init(
            id: order.id,
            status: order.status.rawValue,
            totalAmount: order.totalAmount,
            createdAt: order.createdAt,
            updatedAt: order.updatedAt
        )
    }

    func toDomain() -> Order {
        Order(
            id: id,
            status: Order.Status(rawValue: status) ?? .unknown,
            totalAmount: totalAmount,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
```

---

## ModelContainer Setup

```swift
// Core/Persistence/PersistenceContainer.swift
import SwiftData

enum PersistenceContainer {
    @MainActor
    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            OrderEntity.self,
            // Add all @Model types here
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}
```

Wire in App entry point:
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(try! PersistenceContainer.make())
    }
}
```

---

## Repository

```swift
// Features/Orders/OrderPersistenceRepository.swift
import SwiftData

protocol OrderPersistenceRepositoryProtocol: Sendable {
    func save(_ order: Order) async throws
    func fetch(id: String) async throws -> Order?
    func fetchAll() async throws -> [Order]
    func delete(id: String) async throws
}

@MainActor
final class SwiftDataOrderRepository: OrderPersistenceRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ order: Order) async throws {
        let entity = OrderEntity(from: order)
        context.insert(entity)
        do {
            try context.save()
        } catch {
            throw AppPersistenceError.saveFailed(underlying: error)
        }
    }

    func fetch(id: String) async throws -> Order? {
        let descriptor = FetchDescriptor<OrderEntity>(
            predicate: #Predicate { $0.id == id }
        )
        do {
            return try context.fetch(descriptor).first?.toDomain()
        } catch {
            throw AppPersistenceError.fetchFailed(underlying: error)
        }
    }

    func fetchAll() async throws -> [Order] {
        let descriptor = FetchDescriptor<OrderEntity>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        do {
            return try context.fetch(descriptor).map { $0.toDomain() }
        } catch {
            throw AppPersistenceError.fetchFailed(underlying: error)
        }
    }

    func delete(id: String) async throws {
        let descriptor = FetchDescriptor<OrderEntity>(
            predicate: #Predicate { $0.id == id }
        )
        guard let entity = try context.fetch(descriptor).first else {
            throw AppPersistenceError.notFound(id: id)
        }
        context.delete(entity)
        do {
            try context.save()
        } catch {
            throw AppPersistenceError.deleteFailed(underlying: error)
        }
    }
}
```

---

## In-Memory Repository for Tests

```swift
// Tests/Mocks/InMemoryOrderRepository.swift
final actor InMemoryOrderRepository: OrderPersistenceRepositoryProtocol {
    private var store: [String: Order] = [:]

    func save(_ order: Order) async throws {
        store[order.id] = order
    }

    func fetch(id: String) async throws -> Order? {
        store[id]
    }

    func fetchAll() async throws -> [Order] {
        Array(store.values).sorted { $0.updatedAt > $1.updatedAt }
    }

    func delete(id: String) async throws {
        guard store[id] != nil else { throw AppPersistenceError.notFound(id: id) }
        store.removeValue(forKey: id)
    }
}
```

---

## Schema Migration

When modifying an existing `@Model`, define a migration plan:

```swift
// Core/Persistence/Migrations/MigrationPlan.swift
import SwiftData

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        SchemaV1.self,
        SchemaV2.self
    ]

    static var stages: [MigrationStage] = [
        migrateV1toV2
    ]

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
```

---

## project.yml — no additional setup needed

SwiftData is part of iOS 17 SDK. No extra packages required.

---

## Spec Parser Integration

When brief mentions offline / local data, add to `01-spec.md`:

```markdown
## Persistence
| Entity | Key fields | Cache duration | Sync strategy |
|---|---|---|---|
| `OrderEntity` | `id`, `status`, `updatedAt` | 24h | Refresh on pull-to-refresh |
```

---

## Self-check

- [ ] `@Model` class has `@Attribute(.unique)` on ID
- [ ] Domain model and Entity are separate types — mapped via extension
- [ ] `ModelContainer` set up in App entry, injected via environment
- [ ] Repository uses `AppPersistenceError` for all thrown errors
- [ ] `InMemoryRepository` exists in Tests/Mocks/ for every persistence repository
- [ ] Schema migrations defined when modifying existing `@Model`
- [ ] ViewModels never import `SwiftData`
