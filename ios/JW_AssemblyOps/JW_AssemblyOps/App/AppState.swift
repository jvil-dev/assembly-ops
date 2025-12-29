//
//  AppState.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/26/25.
//

// MARK: - App State
//
// Global singleton managing authentication state and current user session.
// Observed by the root view to control navigation between auth and main flows.
//
// Properties:
//   - isLoggedIn: Whether user has valid auth tokens
//   - isLoading: True during initial auth check on app launch
//   - currentVolunteer: Cached volunteer info after login
//
// Methods:
//   - checkAuthState(): Verify stored tokens on app launch
//   - refreshTokenIfNeeded(): Exchange expired access token for new one
//   - didLogin(volunteer:accessToken:refreshToken:expiresIn:): Store tokens after successful login
//   - logout(): Clear all tokens and reset state
//
// Flow:
//   1. App launches → checkAuthState() runs
//   2. If tokens exist and valid → isLoggedIn = true
//   3. If tokens expired → refreshTokenIfNeeded() attempts refresh
//   4. On refresh failure → logout() clears state
//
// Dependencies:
//   - KeychainManager: Secure token storage
//   - NetworkClient: GraphQL API calls for token refresh
//
// Used by: JW_AssemblyOpsApp.swift (root view switching)

import Foundation
import SwiftUI
import Combine
import Apollo

/// Global app state for authentication and navigation
@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = true
    @Published var currentVolunteer: VolunteerInfo?

    private init() {
        checkAuthState()
    }

    /// Check if user is already logged in on app launch
    func checkAuthState() {
        isLoading = true

        if KeychainManager.shared.isLoggedIn {
            if KeychainManager.shared.isTokenExpired {
                // Token expired, try to refresh
                refreshTokenIfNeeded()
            } else {
                isLoggedIn = true
                isLoading = false
            }
        } else {
            isLoggedIn = false
            isLoading = false
        }
    }

    /// Refresh access token using refresh token
    func refreshTokenIfNeeded() {
        guard let refreshToken = KeychainManager.shared.refreshToken else {
            logout()
            return
        }

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.RefreshTokenMutation(
                input: .init(refreshToken: refreshToken)
            )
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.refreshToken {
                        KeychainManager.shared.saveTokens(
                            accessToken: data.accessToken,
                            refreshToken: data.refreshToken,
                            expiresIn: data.expiresIn
                        )
                        self?.isLoggedIn = true
                    } else {
                        self?.logout()
                    }
                case .failure(let error):
                    print("Token refresh failed: \(error)")
                    self?.logout()
                }
                self?.isLoading = false
            }
        }
    }

    /// Log out and clear all stored data
    func logout() {
        KeychainManager.shared.clearAll()
        currentVolunteer = nil
        isLoggedIn = false
        NetworkClient.shared.resetClient()
    }

    /// Called after successful login
    func didLogin(volunteer: VolunteerInfo, accessToken: String, refreshToken: String, expiresIn: Int) {
        KeychainManager.shared.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
        KeychainManager.shared.volunteerId = volunteer.id
        currentVolunteer = volunteer
        isLoggedIn = true
        NetworkClient.shared.resetClient()
    }
}

/// Volunteer info stored in app state
struct VolunteerInfo: Identifiable {
    let id: String
    let volunteerId: String
    let firstName: String
    let lastName: String
    let fullName: String
    let congregation: String
    let eventName: String?
    let departmentName: String?
}
