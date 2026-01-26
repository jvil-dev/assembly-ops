//
//  OverseerLoginViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/17/26.
//

// MARK: - Overseer Login View Model
//
// Handles overseer authentication via email/password and OAuth providers.
// Supports traditional login and Sign in with Apple/Google flows.
//
// Properties:
//   - email/password: Form fields for traditional login
//   - isLoading: True during authentication requests
//   - errorMessage: User-facing error text for failed attempts
//   - showOAuthRegistration: Triggers navigation to complete OAuth profile
//   - pendingOAuthData: Temporary data for new OAuth users needing registration
//
// Types:
//   - PendingOAuthData: Holds pending token and user info from OAuth provider
//
// Methods:
//   - login(): Authenticate with email/password via LoginAdminMutation
//   - signInWithGoogle(): Initiate Google OAuth flow
//   - signInWithApple(): Initiate Apple OAuth flow
//
// Flow:
//   1. User enters credentials or taps OAuth button
//   2. ViewModel calls appropriate GraphQL mutation
//   3. On success: AppState.didLoginAsOverseer() stores tokens and updates state
//   4. On OAuth with new user: Shows OAuthRegistrationView to complete profile
//

import Foundation
import Combine
import Apollo
import SwiftUI
import AuthenticationServices

@MainActor
final class OverseerLoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showOAuthRegistration: Bool = false
    @Published var pendingOAuthData: PendingOAuthData?

    struct PendingOAuthData {
        let pendingToken: String
        let email: String
        let firstName: String?
        let lastName: String?
    }

    private let appState = AppState.shared

    var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }

    func login() {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        let input = AssemblyOpsAPI.LoginAdminInput(
            email: email.lowercased().trimmingCharacters(in: .whitespaces),
            password: password
        )

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.LoginAdminMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.loginAdmin {
                        let overseer = OverseerInfo(
                            id: data.admin.id,
                            email: data.admin.email,
                            fullName: data.admin.fullName,
                            overseerType: ""
                        )
                        self?.appState.didLoginAsOverseer(overseer: overseer, accessToken: data.accessToken, refreshToken: data.refreshToken, expiresIn: data.expiresIn)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.localizedDescription ?? "Login failed"
                    }
                case .failure(let error):
                    self?.errorMessage = "Unable to connect. Please check your internet connection."
                    print("Login error: \(error)")
                }
                self?.isLoading = false
            }
        }
    }

    // MARK: - OAuth

    func signInWithGoogle() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else { return }

        Task {
            isLoading = true
            errorMessage = nil
            do {
                let idToken = try await OAuthService.shared.signInWithGoogle(presenting: rootVC)
                handleGoogleLogin(idToken: idToken)
            } catch {
                if (error as NSError).code != -5 { // Not cancelled
                    errorMessage = "Google sign-in failed"
                }
                isLoading = false
            }
        }
    }

    func signInWithApple() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                let result = try await OAuthService.shared.signInWithApple()
                handleAppleLogin(result: result)
            } catch let error as ASAuthorizationError where error.code == .canceled {
                // User cancelled
                isLoading = false
            } catch {
                errorMessage = "Apple sign-in failed"
                isLoading = false
            }
        }
    }

    private func handleGoogleLogin(idToken: String) {
        let input = AssemblyOpsAPI.GoogleAuthInput(idToken: idToken)

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.LoginWithGoogleMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.loginWithGoogle {
                        self?.processOAuthResponse(
                            isNewUser: data.isNewUser,
                            admin: data.admin.map { admin in
                                OverseerInfo(
                                    id: admin.id,
                                    email: admin.email,
                                    fullName: admin.fullName,
                                    overseerType: ""
                                )
                            },
                            accessToken: data.accessToken,
                            refreshToken: data.refreshToken,
                            expiresIn: data.expiresIn,
                            pendingOAuthToken: data.pendingOAuthToken,
                            email: data.email,
                            firstName: data.firstName,
                            lastName: data.lastName
                        )
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.localizedDescription ?? "Login failed"
                    }
                case .failure(let error):
                    self?.errorMessage = "Unable to connect. Please try again."
                    print("Google login error: \(error)")
                }
                self?.isLoading = false
            }
        }
    }

    private func handleAppleLogin(result: OAuthService.AppleAuthResult) {
        let input = AssemblyOpsAPI.AppleAuthInput(
            identityToken: result.identityToken,
            firstName: result.firstName.map { .some($0) } ?? .none,
            lastName: result.lastName.map { .some($0) } ?? .none
        )

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.LoginWithAppleMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.loginWithApple {
                        self?.processOAuthResponse(
                            isNewUser: data.isNewUser,
                            admin: data.admin.map { admin in
                                OverseerInfo(
                                    id: admin.id,
                                    email: admin.email,
                                    fullName: admin.fullName,
                                    overseerType: ""
                                )
                            },
                            accessToken: data.accessToken,
                            refreshToken: data.refreshToken,
                            expiresIn: data.expiresIn,
                            pendingOAuthToken: data.pendingOAuthToken,
                            email: data.email,
                            firstName: data.firstName,
                            lastName: data.lastName
                        )
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.localizedDescription ?? "Login failed"
                    }
                case .failure(let error):
                    self?.errorMessage = "Unable to connect. Please try again."
                    print("Apple login error: \(error)")
                }
                self?.isLoading = false
            }
        }
    }

    private func processOAuthResponse(
        isNewUser: Bool,
        admin: OverseerInfo?,
        accessToken: String?,
        refreshToken: String?,
        expiresIn: Int?,
        pendingOAuthToken: String?,
        email: String,
        firstName: String?,
        lastName: String?
    ) {
        if isNewUser {
            // Navigate to registration view
            pendingOAuthData = PendingOAuthData(
                pendingToken: pendingOAuthToken ?? "",
                email: email,
                firstName: firstName,
                lastName: lastName
            )
            showOAuthRegistration = true
        } else if let admin = admin,
                  let accessToken = accessToken,
                  let refreshToken = refreshToken,
                  let expiresIn = expiresIn {
            appState.didLoginAsOverseer(
                overseer: admin,
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresIn: expiresIn
            )
        }
    }
}
