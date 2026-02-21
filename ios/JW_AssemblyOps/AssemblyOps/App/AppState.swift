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
    @Published var needsProfileSetup: Bool = false
    @Published var needsEventSetup: Bool = false
    
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
                            eventId: profile.event.id,
                            eventName: profile.event.name,
                            eventVenue: profile.event.venue,
                            eventTheme: nil,
                            departmentId: profile.department?.id,
                            departmentName: profile.department?.name,
                            departmentType: profile.department?.departmentType.rawValue
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
        NetworkClient.shared.apollo.fetch(
            query: AssemblyOpsAPI.MeQuery(),
            cachePolicy: .fetchIgnoringCacheData
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let me = graphQLResult.data?.me {
                        self?.currentOverseer = OverseerInfo(
                            id: me.id,
                            email: me.email,
                            fullName: me.fullName,
                            firstName: me.firstName,
                            lastName: me.lastName,
                            phone: me.phone,
                            congregationId: me.congregationId,
                            circuitId: me.congregationRef?.circuit.id,
                            overseerType: ""
                        )
                        self?.needsProfileSetup = me.congregationId == nil
                    }
                    // After profile, check if overseer has events
                    self?.checkOverseerEvents()
                case .failure(let error):
                    print("Overseer profile fetch failed: \(error)")
                    // Network error but tokens exist - proceed
                    self?.isLoggedIn = true
                    self?.isLoading = false
                }
            }
        }
    }

    /// Check if overseer has any events (after profile is loaded)
    private func checkOverseerEvents() {
        NetworkClient.shared.apollo.fetch(
            query: AssemblyOpsAPI.MyEventsQuery(),
            cachePolicy: .fetchIgnoringCacheData
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    let eventCount = graphQLResult.data?.myEvents.count ?? 0
                    self?.needsEventSetup = eventCount == 0
                case .failure:
                    // Network error - don't block, assume they might have events
                    self?.needsEventSetup = false
                }
                self?.isLoggedIn = true
                self?.isLoading = false
            }
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
                        // Recreate Apollo client with new auth headers
                        NetworkClient.shared.resetClient()
                        // Fetch profile after refresh (populates currentOverseer/currentVolunteer
                        // and checks needsProfileSetup/needsEventSetup)
                        self?.fetchUserProfile()
                    } else {
                        self?.logout()
                        self?.isLoading = false
                    }
                case .failure(let error):
                    print("Token refresh failed: \(error)")
                    self?.logout()
                    self?.isLoading = false
                }
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
        needsProfileSetup = false
        needsEventSetup = false
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
        userType = .overseer
        NetworkClient.shared.resetClient()

        // Fetch full profile from server (login responses may have partial data,
        // e.g. OAuth logins don't return congregationId). This also chains into
        // checkOverseerEvents() to determine needsEventSetup.
        fetchOverseerProfile()
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
    let eventId: String
    let eventName: String?
    let eventVenue: String?
    let eventTheme: String?
    let departmentId: String?
    let departmentName: String?
    let departmentType: String?
}

/// Overseer info stored in app state
struct OverseerInfo: Identifiable {
    let id: String
    let email: String
    let fullName: String
    let firstName: String
    let lastName: String
    let phone: String?
    let congregationId: String?
    let circuitId: String?
    let overseerType: String

    var isProfileComplete: Bool {
        congregationId != nil && !fullName.trimmingCharacters(in: .whitespaces).isEmpty
    }

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
