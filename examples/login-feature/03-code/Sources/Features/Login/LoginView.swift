// ============================================================
// LoginView.swift
// AC coverage: AC-1, AC-2, AC-3, AC-4
// Depends on: LoginViewModel.swift, Theme.swift
// ============================================================

import SwiftUI

// MARK: - LoginView

/// Presented as a fullScreenCover by RootView (Rule N-3).
/// Dismissed via @Binding when login succeeds (Rule N-4).
/// No NavigationStack inside this view (Rule N-1).
struct LoginView: View {

    // MARK: - Dependencies

    @State var viewModel: LoginViewModel
    @Binding var showLogin: Bool

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.appSurface.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.sectionGap) {
                    headerSection
                    formSection
                }
                .padding(.horizontal, AppSpacing.pagePadding)
                .padding(.top, AppSpacing.xl)
            }

            // AC-3: loading overlay disables all interaction
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .onChange(of: viewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                showLogin = false   // AC-1: dismiss cover, RootView shows HomeView
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.appPrimary)
                .accessibilityHidden(true)  // A-3: decorative

            Text("Welcome Back")
                .font(.appTitle)
                .accessibilityAddTraits(.isHeader)

            Text("Sign in to continue")
                .font(.appBody)
                .foregroundStyle(.appSubtle)
        }
        .frame(maxWidth: .infinity)
    }

    private var formSection: some View {
        VStack(spacing: AppSpacing.fieldGap) {

            // Email field
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.appBody)
                    .padding(AppSpacing.sm)
                    .background(.appSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.field)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                    .disabled(viewModel.isLoading)  // AC-3: disabled during loading
                    .accessibilityLabel("Email address")
                    .accessibilityIdentifier("login_email_input")  // A-2
            }

            // Password field
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SecureField("Password", text: $viewModel.password)
                    .textContentType(.password)
                    .font(.appBody)
                    .padding(AppSpacing.sm)
                    .background(.appSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.field)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                    .disabled(viewModel.isLoading)  // AC-3: disabled during loading
                    .accessibilityLabel("Password")
                    .accessibilityIdentifier("login_password_input")  // A-2
            }

            // AC-2: error message — shown only on failure
            if let message = viewModel.errorMessage {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.appError)
                        .accessibilityHidden(true)
                    Text(message)
                        .font(.appCaption)
                        .foregroundStyle(.appError)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(message)
                .accessibilityIdentifier("login_error_message")  // A-2
                .transition(.opacity)
            }

            // Sign In button — AC-4: disabled when fields empty
            Button {
                Task { await viewModel.login() }
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    if viewModel.isLoading {
                        ProgressView().tint(.white).scaleEffect(0.8)
                            .accessibilityHidden(true)
                    }
                    Text(viewModel.isLoading ? "Signing in…" : "Sign In")
                        .font(.appBody.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.isLoginEnabled ? Color.appPrimary : Color.appSubtle)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
            }
            .disabled(!viewModel.isLoginEnabled)
            .accessibilityLabel(viewModel.isLoading ? "Signing in" : "Sign In")
            .accessibilityIdentifier("login_sign_in_button")  // A-2
            .animation(.easeInOut(duration: 0.15), value: viewModel.isLoginEnabled)
        }
    }

    private var loadingOverlay: some View {
        Color.black.opacity(0.1)
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview("Initial state") {
    LoginView(
        viewModel: LoginViewModel(authService: MockAuthService()),
        showLogin: .constant(true)
    )
}

#Preview("Error state") {
    let vm = LoginViewModel(authService: MockAuthService())
    return LoginView(viewModel: vm, showLogin: .constant(true))
        .onAppear {
            vm.email = "user@example.com"
        }
}

// MARK: - MockAuthService (preview only)

private final class MockAuthService: AuthServiceProtocol {
    func login(credentials: LoginCredentials) async throws -> AuthSession {
        try await Task.sleep(for: .seconds(1))
        throw AuthError.invalidCredentials
    }
}
