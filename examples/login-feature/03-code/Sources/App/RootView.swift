// ============================================================
// RootView.swift
// AC coverage: AC-1 (session check on launch)
// Depends on: LoginView.swift, LoginViewModel.swift, AuthRepository.swift
// ============================================================

import SwiftUI

/// Root of the navigation hierarchy.
/// Owns the single NavigationStack (Rule N-1).
/// Presents LoginView as fullScreenCover (Rule N-3).
struct RootView: View {

    // MARK: - State

    @State private var showLogin: Bool = true

    // MARK: - Body

    var body: some View {
        NavigationStack {
            HomeView()
                // All navigationDestinations registered here (Rule N-2)
                // .navigationDestination(for: Route.self) { … }
        }
        .fullScreenCover(isPresented: $showLogin) {
            // Rule N-3: LoginView is a fullScreenCover — no back button
            // Rule N-4: dismissed via @Binding, not internal @State
            LoginView(
                viewModel: LoginViewModel(authService: AuthRepository()),
                showLogin: $showLogin
            )
        }
        .onAppear {
            // AC-1 edge case: skip login if valid session exists
            showLogin = !SessionManager.hasValidSession()
        }
    }
}

// MARK: - HomeView (placeholder)

struct HomeView: View {
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.appPrimary)
                .accessibilityHidden(true)
            Text("Welcome!")
                .font(.appTitle)
            Text("You are signed in.")
                .font(.appBody)
                .foregroundStyle(.appSubtle)
        }
        .navigationTitle("Home")
        .accessibilityElement(children: .contain)
    }
}

// MARK: - SessionManager

enum SessionManager {
    static func hasValidSession() -> Bool {
        guard let token = KeychainHelper.load(for: .authToken) else { return false }
        return !token.isEmpty
    }
}

// MARK: - Preview

#Preview {
    RootView()
}
