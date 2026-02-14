//
//  OverseerRegistrationViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Overseer Registration View Model
//
// Handles new overseer account creation via email/password or OAuth providers.
// Validates form input and performs RegisterAdminMutation.
//
// Properties:
//   - email/password/confirmPassword: Account credential fields
//   - firstName/lastName: Required name fields
//   - isLoading: True during registration request
//   - errorMessage: User-facing error for failed registration
//   - showOAuthRegistration: Triggers OAuth completion flow
//   - pendingOAuthData: Temporary data for OAuth users completing registration
//
// Validation:
//   - Email must not be empty
//   - Password must be 8+ characters and match confirmation
//   - First name and last name are required
//
// Methods:
//   - register(): Create account via RegisterAdminMutation
//   - signInWithGoogle()/signInWithApple(): OAuth registration flows
//
// Flow:
//   1. User fills form or uses OAuth
//   2. On success: AppState.didLoginAsOverseer() logs user in
//   3. On OAuth new user: Shows OAuthRegistrationView for profile completion
//

import Foundation
import AuthenticationServices
import Combine
import Apollo

@MainActor
final class OverseerRegistrationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showOAuthRegistration = false
    @Published var pendingOAuthData: PendingOAuthData?
    
    struct PendingOAuthData {
        let pendingToken: String
        let email: String
        let firstName: String
        let lastName: String
    }
    
    private var appState = AppState.shared
    
    var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 8 &&
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var passwordsMatch: Bool {
        password == confirmPassword
    }
    
    // MARK: - Email/Password Registration
    
    func register() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        let input = AssemblyOpsAPI.RegisterAdminInput(
            email: email.lowercased().trimmingCharacters(in: .whitespaces),
            password: password,
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces)
        )
        
        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.RegisterAdminMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.registerAdmin {
                        let overseer = OverseerInfo(
                            id: data.admin.id,
                            email: data.admin.email,
                            fullName: data.admin.fullName,
                            firstName: data.admin.firstName,
                            lastName: data.admin.lastName,
                            phone: nil,
                            congregationId: nil,
                            circuitId: nil,
                            overseerType: ""
                        )
                        self?.appState.didLoginAsOverseer(overseer: overseer, accessToken: data.accessToken, refreshToken: data.refreshToken, expiresIn: data.expiresIn)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.localizedDescription ?? "Registration failed"
                    }
                case .failure: self?.errorMessage = "Unable to connect. Please try again."
                }
                self?.isLoading = false
            }
        }
    }
    
    //MARK: - OAuth Registration (resuse from OverseerLoginViewModel)
    
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
    
    // MARK: - OAuth Handlers

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
                                    firstName: admin.firstName,
                                    lastName: admin.lastName,
                                    phone: nil,
                                    congregationId: nil,
                                    circuitId: nil,
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
                        self?.errorMessage = errors.first?.localizedDescription ?? "Registration failed"
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
                            admin: data.admin.map { admin in
                                OverseerInfo(
                                    id: admin.id,
                                    email: admin.email,
                                    fullName: admin.fullName,
                                    firstName: admin.firstName,
                                    lastName: admin.lastName,
                                    phone: nil,
                                    congregationId: nil,
                                    circuitId: nil,
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
                        self?.errorMessage = errors.first?.localizedDescription ?? "Registration failed"
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
            // Navigate to OAuth registration view to complete profile
            pendingOAuthData = PendingOAuthData(
                pendingToken: pendingOAuthToken ?? "",
                email: email,
                firstName: firstName ?? "",
                lastName: lastName ?? ""
            )
            showOAuthRegistration = true
        } else if let admin = admin,
                  let accessToken = accessToken,
                  let refreshToken = refreshToken,
                  let expiresIn = expiresIn {
            // Existing user - log them in
            appState.didLoginAsOverseer(
                overseer: admin,
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresIn: expiresIn
            )
        }
    }
}
