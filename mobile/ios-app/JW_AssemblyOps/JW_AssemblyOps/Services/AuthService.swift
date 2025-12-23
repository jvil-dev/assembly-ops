//
//  AuthService.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/23/25.
//

import Foundation

@Observable
final class AuthService {
    
    // MARK: - Singleton
    
    static let shared = AuthService()
    
    // MARK: - Properties
    
    private(set) var currentOverseer: OverseerDTO?
    private(set) var currentVolunteer: VolunteerDTO?
    private(set) var isAuthenticated: Bool = false
    private(set) var userType: UserType?
    
    enum UserType {
        case overseer
        case volunteer
    }
    
    // MARK: - Init
    
    private init() {
        // Check for existing session on init
        checkExistingSession()
    }
    
    // MARK: - Session Check
    
    private func checkExistingSession() {
        if KeychainManager.shared.isOverseerLoggedIn {
            isAuthenticated = true
            userType = .overseer
        } else if KeychainManager.shared.isVolunteerLoggedIn {
            isAuthenticated = true
            userType = .volunteer
        }
    }
    
    // MARK: - Overseer Auth
    
    /// Register a new overseer account
    func registerOverseer(email: String, password: String, name: String) async throws -> OverseerDTO {
        let request = OverseerRegisterRequest(
            email: email,
            password: password,
            name: name
        )
        
        let response: APIResponse<OverseerAuthResponse> = try await APIClient.shared.post(
            "/auth/admin/register",  // Backend endpoint uses "admin"
            body: request,
            requiresAuth: false
        )
        
        guard let authData = response.data else {
            throw APIError.noData
        }
        
        // Save tokens
        saveOverseerSession(authData)
        
        return authData.overseer
    }
    
    /// Login with overseer credentials
    func loginOverseer(email: String, password: String) async throws -> OverseerDTO {
        let request = OverseerLoginRequest(
            email: email,
            password: password
        )
        
        let response: APIResponse<OverseerAuthResponse> = try await APIClient.shared.post(
            "/auth/admin/login",  // Backend endpoint uses "admin"
            body: request,
            requiresAuth: false
        )
        
        guard let authData = response.data else {
            throw APIError.noData
        }
        
        // Save tokens
        saveOverseerSession(authData)
        
        return authData.overseer
    }
    
    /// Refresh overseer access token
    func refreshOverseerToken() async throws {
        guard let refreshToken = KeychainManager.shared.overseerRefreshToken else {
            throw APIError.unauthorized
        }
        
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        
        let response: APIResponse<RefreshTokenResponse> = try await APIClient.shared.post(
            "/auth/admin/refresh",
            body: request,
            requiresAuth: false
        )
        
        guard let tokenData = response.data else {
            throw APIError.noData
        }
        
        // Update tokens
        KeychainManager.shared.overseerAccessToken = tokenData.accessToken
        KeychainManager.shared.overseerRefreshToken = tokenData.refreshToken
    }
    
    private func saveOverseerSession(_ authData: OverseerAuthResponse) {
        KeychainManager.shared.overseerAccessToken = authData.accessToken
        KeychainManager.shared.overseerRefreshToken = authData.refreshToken
        KeychainManager.shared.overseerId = authData.overseer.id
        KeychainManager.shared.userType = "overseer"
        
        currentOverseer = authData.overseer
        isAuthenticated = true
        userType = .overseer
    }
    
    // MARK: - Volunteer Auth
    
    /// Login with volunteer credentials
    func loginVolunteer(odid: String, token: String, eventId: String) async throws -> VolunteerDTO {
        let request = VolunteerLoginRequest(
            odid: odid,
            token: token,
            eventId: eventId
        )
        
        let response: APIResponse<VolunteerAuthResponse> = try await APIClient.shared.post(
            "/auth/volunteer/login",
            body: request,
            requiresAuth: false
        )
        
        guard let authData = response.data else {
            throw APIError.noData
        }
        
        // Save tokens
        saveVolunteerSession(authData, eventId: eventId)
        
        return authData.volunteer
    }
    
    private func saveVolunteerSession(_ authData: VolunteerAuthResponse, eventId: String) {
        KeychainManager.shared.volunteerToken = authData.token
        KeychainManager.shared.volunteerId = authData.volunteer.id
        KeychainManager.shared.currentEventId = eventId
        KeychainManager.shared.userType = "volunteer"
        
        currentVolunteer = authData.volunteer
        isAuthenticated = true
        userType = .volunteer
    }
    
    // MARK: - Logout
    
    func logout() {
        currentOverseer = nil
        currentVolunteer = nil
        isAuthenticated = false
        userType = nil
        
        KeychainManager.shared.clearAllSessions()
    }
    
    func logoutOverseer() {
        currentOverseer = nil
        if userType == .overseer {
            isAuthenticated = false
            userType = nil
        }
        KeychainManager.shared.clearOverseerSession()
    }
    
    func logoutVolunteer() {
        currentVolunteer = nil
        if userType == .volunteer {
            isAuthenticated = false
            userType = nil
        }
        KeychainManager.shared.clearVolunteerSession()
    }
    
    // MARK: - Fetch Current User
    
    /// Fetch current overseer profile from server
    func fetchCurrentOverseer() async throws -> OverseerDTO {
        guard let overseerId = KeychainManager.shared.overseerId else {
            throw APIError.unauthorized
        }
        
        let response: APIResponse<OverseerDTO> = try await APIClient.shared.get(
            "/admins/\(overseerId)"  // Backend uses "admins"
        )
        
        guard let overseer = response.data else {
            throw APIError.noData
        }
        
        currentOverseer = overseer
        return overseer
    }
    
    /// Fetch current volunteer profile from server
    func fetchCurrentVolunteer() async throws -> VolunteerDTO {
        guard let volunteerId = KeychainManager.shared.volunteerId,
              let eventId = KeychainManager.shared.currentEventId else {
            throw APIError.unauthorized
        }
        
        let response: APIResponse<VolunteerDTO> = try await APIClient.shared.get(
            "/events/\(eventId)/volunteers/\(volunteerId)"
        )
        
        guard let volunteer = response.data else {
            throw APIError.noData
        }
        
        currentVolunteer = volunteer
        return volunteer
    }
}
