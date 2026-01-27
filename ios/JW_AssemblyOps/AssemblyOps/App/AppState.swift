//
//  AppState.swift
//  AssemblyOps
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
    @Published var currentOverseer: OverseerInfo?
    @Published var userType: UserType = .unknown
    
    enum UserType {
        case unknown
        case volunteer
        case overseer
    }

    private init() {
        checkAuthState()
    }

    /// Check if user is already logged in on app launch
    func checkAuthState() {
        isLoading = true

        if KeychainManager.shared.isLoggedIn {
            // Restore user type from keychain
            if KeychainManager.shared.userType == "overseer" {
                userType = .overseer
            } else {
                userType = .volunteer
            }

            if KeychainManager.shared.isTokenExpired {
                // Token expired, try to refresh
                refreshTokenIfNeeded()
            } else {
                // Fetch user profile to populate current user info
                fetchUserProfile()
            }
        } else {
            isLoggedIn = false
            isLoading = false
        }
    }

    /// Fetch user profile after session restore
    private func fetchUserProfile() {
        if userType == .volunteer {
            fetchVolunteerProfile()
        } else if userType == .overseer {
            fetchOverseerProfile()
        } else {
            isLoggedIn = true
            isLoading = false
        }
    }

    /// Fetch volunteer profile from server
    private func fetchVolunteerProfile() {
        NetworkClient.shared.apollo.fetch(
            query: AssemblyOpsAPI.MyVolunteerProfileQuery(),
            cachePolicy: .fetchIgnoringCacheData
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let profile = graphQLResult.data?.myVolunteerProfile {
                        self?.currentVolunteer = VolunteerInfo(
                            id: profile.id,
                            volunteerId: profile.volunteerId,
                            firstName: profile.firstName,
                            lastName: profile.lastName,
                            fullName: profile.fullName,
                            congregation: profile.congregation,
                            eventName: profile.event.name,
                            eventVenue: profile.event.venue,
                            eventTheme: nil,
                            departmentName: profile.department?.name
                        )
                        self?.isLoggedIn = true
                    } else {
                        // Profile fetch failed, but tokens are valid - proceed anyway
                        self?.isLoggedIn = true
                    }
                case .failure(let error):
                    print("Profile fetch failed: \(error)")
                    // Network error but tokens exist - proceed with login
                    self?.isLoggedIn = true
                }
                self?.isLoading = false
            }
        }
    }

    /// Fetch overseer profile from server
    private func fetchOverseerProfile() {
        // TODO: Add MyOverseerProfile query when available
        // For now, just proceed with login
        isLoggedIn = true
        isLoading = false
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
        AssignmentCache.shared.clear()
        currentVolunteer = nil
        currentOverseer = nil
        userType = .unknown
        isLoggedIn = false
        NetworkClient.shared.resetClient()
    }

    /// Called after successful volunteer login
    func didLoginAsVolunteer(volunteer: VolunteerInfo, accessToken: String, refreshToken: String, expiresIn: Int) {
        KeychainManager.shared.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
        KeychainManager.shared.volunteerId = volunteer.id
        KeychainManager.shared.userType = "volunteer"
        currentVolunteer = volunteer
        userType = .volunteer
        isLoggedIn = true
        NetworkClient.shared.resetClient()
    }
    
    /// Called after successful overseer login
    func didLoginAsOverseer(overseer: OverseerInfo, accessToken: String, refreshToken: String, expiresIn: Int) {
        KeychainManager.shared.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
        KeychainManager.shared.overseerId = overseer.id
        KeychainManager.shared.userType = "overseer"
        currentOverseer = overseer
        userType = .overseer
        isLoggedIn = true
        NetworkClient.shared.resetClient()
        
    }
    
    var isOverseer: Bool {
        userType == .overseer
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
    let eventVenue: String?
    let eventTheme: String?
    let departmentName: String?
}

/// Overseer info stored in app state
struct OverseerInfo: Identifiable {
    let id: String
    let email: String
    let fullName: String
    let overseerType: String

    var initials: String {
        let names = fullName.split(separator: " ")
        if names.count >= 2 {
            return "\(names[0].prefix(1))\(names[1].prefix(1))".uppercased()
        } else if let first = names.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
}
