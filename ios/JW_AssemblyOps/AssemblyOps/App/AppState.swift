//
//  AppState.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 12/26/25.
//

// MARK: - App State
//
// Global singleton managing authentication state and current user session.
// All users land on EventsHomeView after login (no role branching at root).
//
// Properties:
//   - isLoggedIn: Whether user has valid auth tokens
//   - isLoading: True during initial auth check on app launch
//   - currentUser: Unified user info (both overseers and volunteers)
//   - hasVolunteerEventMembership: Whether volunteer has active event context
//   - currentEventId: Active event context for volunteer tab views
//
// Methods:
//   - checkAuthState(): Verify stored tokens on app launch
//   - refreshTokenIfNeeded(): Exchange expired access token for new one
//   - didLogin(user:...): Store tokens after unified user login
//   - didUpdateOverseerMode(isOverseer:): Update user's overseer flag
//   - logout(): Clear all tokens and reset state
//
// Routing (AssemblyOpsApp.swift):
//   isLoading   → LaunchView
//   !isLoggedIn → LandingView
//   isLoggedIn  → EventsHomeView (unified hub for all users)
//
// Dependencies:
//   - KeychainManager: Secure token storage
//   - NetworkClient: GraphQL API calls

import Foundation
import SwiftUI
import Combine
import Apollo

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = true
    @Published var currentUser: UserInfo?
    /// True when a volunteer has active event context (set by EventTabView).
    @Published var hasVolunteerEventMembership: Bool = false
    /// The eventId for the volunteer's current event. Set by EventTabView.
    @Published var currentEventId: String?

    var isOverseer: Bool {
        currentUser?.isOverseer ?? false
    }

    private init() {
        checkAuthState()
    }

    // MARK: - Auth State

    func checkAuthState() {
        isLoading = true

        guard KeychainManager.shared.isLoggedIn else {
            isLoggedIn = false
            isLoading = false
            return
        }

        if KeychainManager.shared.isTokenExpired {
            refreshTokenIfNeeded()
        } else {
            fetchUserProfile()
        }
    }

    // MARK: - Profile Fetch

    private func fetchUserProfile() {
        fetchMeProfile()
    }

    private func fetchMeProfile() {
        NetworkClient.shared.apollo.fetch(
            query: AssemblyOpsAPI.MeQuery(),
            cachePolicy: .fetchIgnoringCacheData
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let me = graphQLResult.data?.me {
                        self?.currentUser = UserInfo(from: me)
                    }
                case .failure(let error):
                    print("Profile fetch failed: \(error)")
                }
                self?.isLoggedIn = true
                self?.isLoading = false
            }
        }
    }

    // MARK: - Token Refresh

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
                        NetworkClient.shared.resetClient()
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

    // MARK: - Login

    /// Called after successful unified user login (registerUser / loginUser / OAuth)
    func didLogin(user: UserInfo, accessToken: String, refreshToken: String, expiresIn: Int) {
        KeychainManager.shared.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
        KeychainManager.shared.userId = user.id
        currentUser = user
        NetworkClient.shared.resetClient()
        isLoggedIn = true
    }

    /// Called when overseer mode is toggled in profile settings
    func didUpdateOverseerMode(isOverseer: Bool) {
        guard let user = currentUser else { return }
        currentUser = UserInfo(
            id: user.id, userId: user.userId, email: user.email,
            firstName: user.firstName, lastName: user.lastName, fullName: user.fullName,
            phone: user.phone, congregation: user.congregation, congregationId: user.congregationId,
            circuitCode: user.circuitCode, circuitId: user.circuitId,
            appointmentStatus: user.appointmentStatus, isOverseer: isOverseer
        )
    }

    // MARK: - Logout

    func logout() {
        KeychainManager.shared.clearAll()
        AssignmentCache.shared.clear()
        currentUser = nil
        hasVolunteerEventMembership = false
        currentEventId = nil
        isLoggedIn = false
        NetworkClient.shared.resetClient()
    }
}

// MARK: - UserInfo

/// Unified user identity — overseers and volunteers share this type
struct UserInfo: Identifiable {
    let id: String
    let userId: String          // 6-char permanent ID, e.g. "A7X9K2"
    let email: String
    let firstName: String
    let lastName: String
    let fullName: String
    let phone: String?
    let congregation: String?
    let congregationId: String?
    let circuitCode: String?
    let circuitId: String?
    let appointmentStatus: String?
    let isOverseer: Bool

    var initials: String {
        let parts = fullName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(fullName.prefix(2)).uppercased()
    }

    var isProfileComplete: Bool {
        congregationId != nil && !fullName.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

extension UserInfo {
    init(from me: AssemblyOpsAPI.MeQuery.Data.Me) {
        self.id = me.id
        self.userId = me.userId
        self.email = me.email
        self.firstName = me.firstName
        self.lastName = me.lastName
        self.fullName = me.fullName
        self.phone = me.phone
        self.congregation = me.congregation
        self.congregationId = me.congregationId
        self.circuitCode = me.congregationRef?.circuit.code
        self.circuitId = me.congregationRef?.circuit.id
        self.appointmentStatus = me.appointmentStatus?.rawValue
        self.isOverseer = me.isOverseer
    }
}

