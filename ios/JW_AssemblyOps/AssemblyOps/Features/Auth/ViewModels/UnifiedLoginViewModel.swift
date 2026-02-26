//
//  UnifiedLoginViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/24/26.
//

// MARK: - Unified Login View Model
//
// Handles authentication for all users via email/password and OAuth.
// Replaces OverseerLoginViewModel + VolunteerLoginViewModel.
//
// Properties:
//   - email/password: Form fields for email/password login
//   - isLoading: True during authentication requests
//   - errorMessage: User-facing error text
//   - showOAuthRegistration: Triggers navigation to OAuthRegistrationView
//   - pendingOAuthData: Temporary data for new OAuth users
//
// Methods:
//   - login(): Authenticate via loginUser mutation
//   - signInWithGoogle(): Google OAuth flow
//   - signInWithApple(): Apple OAuth flow
//
// Flow:
//   1. User taps Sign In → loginUser mutation
//   2. On success → AppState.didLogin(user:...) → routing via isOverseer
//   3. On OAuth new user → OAuthRegistrationView to complete profile

import Foundation
import Combine
import Apollo
import SwiftUI
import AuthenticationServices

@MainActor
final class UnifiedLoginViewModel: ObservableObject {
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
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    // MARK: - Email/Password

    func login() {
        guard isFormValid else { return }
        isLoading = true
        errorMessage = nil

        let input = AssemblyOpsAPI.LoginUserInput(
            email: email.lowercased().trimmingCharacters(in: .whitespaces),
            password: password
        )

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.LoginUserMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.loginUser {
                        let user = UserInfo(
                            id: data.user.id,
                            userId: data.user.userId,
                            email: data.user.email,
                            firstName: data.user.firstName,
                            lastName: data.user.lastName,
                            fullName: data.user.fullName,
                            phone: data.user.phone,
                            congregation: data.user.congregation,
                            congregationId: data.user.congregationId,
                            appointmentStatus: data.user.appointmentStatus?.rawValue,
                            isOverseer: data.user.isOverseer
                        )
                        self?.appState.didLogin(
                            user: user,
                            accessToken: data.accessToken,
                            refreshToken: data.refreshToken,
                            expiresIn: data.expiresIn
                        )
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.message ?? "Login failed"
                    }
                case .failure:
                    self?.errorMessage = "Unable to connect. Please check your internet connection."
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
                if (error as NSError).code != -5 {
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
                isLoading = false
            } catch {
                errorMessage = "Apple sign-in failed"
                isLoading = false
            }
        }
    }

    private func handleGoogleLogin(idToken: String) {
        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.LoginWithGoogleMutation(
                input: AssemblyOpsAPI.GoogleAuthInput(idToken: idToken)
            )
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.loginWithGoogle {
                        self?.processOAuthResponse(
                            isNewUser: data.isNewUser,
                            userPayload: data.user,
                            accessToken: data.accessToken,
                            refreshToken: data.refreshToken,
                            expiresIn: data.expiresIn,
                            pendingOAuthToken: data.pendingOAuthToken,
                            email: data.email,
                            firstName: data.firstName,
                            lastName: data.lastName
                        )
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.message ?? "Login failed"
                    }
                case .failure:
                    self?.errorMessage = "Unable to connect. Please try again."
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
                            userPayload: data.user,
                            accessToken: data.accessToken,
                            refreshToken: data.refreshToken,
                            expiresIn: data.expiresIn,
                            pendingOAuthToken: data.pendingOAuthToken,
                            email: data.email,
                            firstName: data.firstName,
                            lastName: data.lastName
                        )
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.message ?? "Login failed"
                    }
                case .failure:
                    self?.errorMessage = "Unable to connect. Please try again."
                }
                self?.isLoading = false
            }
        }
    }

    private func processOAuthResponse(
        isNewUser: Bool,
        userPayload: (any _OAuthUserPayload)?,
        accessToken: String?,
        refreshToken: String?,
        expiresIn: Int?,
        pendingOAuthToken: String?,
        email: String,
        firstName: String?,
        lastName: String?
    ) {
        if isNewUser, let token = pendingOAuthToken, !token.isEmpty {
            pendingOAuthData = PendingOAuthData(
                pendingToken: token,
                email: email,
                firstName: firstName,
                lastName: lastName
            )
            showOAuthRegistration = true
        } else if isNewUser {
            errorMessage = "Sign-in failed. Please try again."
        } else if let payload = userPayload,
                  let accessToken = accessToken,
                  let refreshToken = refreshToken,
                  let expiresIn = expiresIn {
            // Dismiss any open OAuth registration sheet before logging in
            showOAuthRegistration = false
            pendingOAuthData = nil
            let user = UserInfo(
                id: payload.id,
                userId: payload.userId,
                email: payload.email,
                firstName: payload.firstName,
                lastName: payload.lastName,
                fullName: payload.fullName,
                phone: nil,
                congregation: nil,
                congregationId: nil,
                appointmentStatus: nil,
                isOverseer: payload.isOverseer
            )
            appState.didLogin(
                user: user,
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresIn: expiresIn
            )
        }
    }
}

// Protocol to unify Google and Apple OAuth user payload shapes
protocol _OAuthUserPayload {
    var id: String { get }
    var userId: String { get }
    var email: String { get }
    var firstName: String { get }
    var lastName: String { get }
    var fullName: String { get }
    var isOverseer: Bool { get }
}

extension AssemblyOpsAPI.LoginWithGoogleMutation.Data.LoginWithGoogle.User: _OAuthUserPayload {}
extension AssemblyOpsAPI.LoginWithAppleMutation.Data.LoginWithApple.User: _OAuthUserPayload {}
