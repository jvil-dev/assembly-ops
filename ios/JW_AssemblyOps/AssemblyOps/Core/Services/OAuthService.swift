//
//  OAuthService.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/24/26.
//

// MARK: - OAuth Service
//
// Singleton service handling third-party OAuth authentication flows.
// Supports Sign in with Apple and Google Sign-In for overseer registration/login.
//
// Types:
//   - AppleAuthResult: Contains identity token and optional name from Apple
//   - OAuthError: Error enum for token retrieval failures
//
// Methods:
//   - signInWithGoogle(presenting:): Initiates Google Sign-In flow, returns ID token
//   - signInWithApple(): Initiates Apple Sign-In flow, returns AppleAuthResult
//
// Implementation Notes:
//   - Uses async/await with CheckedContinuation for callback-based SDKs
//   - Implements ASAuthorizationControllerDelegate for Apple Sign-In callbacks
//   - MainActor isolated to ensure UI operations on main thread
//

import Foundation
import AuthenticationServices
import GoogleSignIn

@MainActor
final class OAuthService: NSObject {
    static let shared = OAuthService()
    
    private var appleSignInContinuation: CheckedContinuation<AppleAuthResult, Error>?
    
    struct AppleAuthResult {
        let identityToken: String
        let firstName: String?
        let lastName: String?
    }
    
    // MARK: - Google Sign-in
    
    func signInWithGoogle(presenting: UIViewController) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let idToken = result?.user.idToken?.tokenString else {
                    continuation.resume(throwing: OAuthError.missingToken)
                    return
                }
                continuation.resume(returning: idToken)
            }
        }
    }
    
    // MARK: - Sign in with Apple
    
    func signInWithApple() async throws -> AppleAuthResult {
        try await withCheckedThrowingContinuation { continuation in
            self.appleSignInContinuation = continuation
            
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }
    }
}

extension OAuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else {
                appleSignInContinuation?.resume(throwing: OAuthError.missingToken)
                appleSignInContinuation = nil
                return
            }
            
            let result = AppleAuthResult(
                identityToken: token,
                firstName: credential.fullName?.givenName,
                lastName: credential.fullName?.familyName
            )
            appleSignInContinuation?.resume(returning: result)
            appleSignInContinuation = nil
        }
    }
    
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            appleSignInContinuation?.resume(throwing: error)
            appleSignInContinuation = nil
        }
    }
}

enum OAuthError: LocalizedError {
    case missingToken
    var errorDescription: String? { "Failed to obtain authentication token" }
}
