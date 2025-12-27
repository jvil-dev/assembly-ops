//
//  AppState.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/26/25.
//

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
