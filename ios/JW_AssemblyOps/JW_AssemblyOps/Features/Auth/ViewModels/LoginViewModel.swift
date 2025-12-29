//
//  LoginViewModel.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Login View Model
//
// Handles volunteer authentication via GraphQL loginVolunteer mutation.
// Manages form state, validation, loading states, and error handling.
//
// Published Properties:
//   - volunteerId: User-entered volunteer ID (e.g., "VOL-ABC123")
//   - token: User-entered auth token
//   - isLoading: True while login request is in flight
//   - errorMessage: Error text to display (nil on success)
//
// Computed Properties:
//   - isFormValid: True if both fields have non-empty values
//
// Methods:
//   - login(): Execute loginVolunteer mutation, store tokens on success
//
// Flow:
//   1. User enters volunteerId and token
//   2. login() validates form, calls GraphQL mutation
//   3. On success: AppState.didLogin() stores tokens, triggers navigation
//   4. On failure: errorMessage displayed to user
//
// Dependencies:
//   - NetworkClient: Apollo GraphQL client
//   - AppState: Stores tokens and triggers auth state change
//
// Used by: LoginView.swift

import Foundation
import SwiftUI
import Combine
import Apollo

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var volunteerId: String = ""
    @Published var token: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let appState = AppState.shared
    
    var isFormValid: Bool {
        !volunteerId.trimmingCharacters(in: .whitespaces).isEmpty &&
        !token.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    func login() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        let input = AssemblyOpsAPI.LoginVolunteerInput(
            volunteerId: volunteerId.uppercased().trimmingCharacters(in: .whitespaces),
            token: token.uppercased().trimmingCharacters(in: .whitespaces)
        )
        
        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.LoginVolunteerMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.loginVolunteer {
                         let volunteer = VolunteerInfo(
                             id: data.volunteer.id,
                             volunteerId: data.volunteer.volunteerId,
                             firstName: data.volunteer.firstName,
                             lastName: data.volunteer.lastName,
                             fullName: data.volunteer.fullName,
                             congregation: data.volunteer.congregation,
                             eventName: data.volunteer.event.name,
                             departmentName: data.volunteer.department?.name
                         )
                         self?.appState.didLogin(
                             volunteer: volunteer,
                             accessToken: data.accessToken,
                             refreshToken: data.refreshToken,
                             expiresIn: data.expiresIn
                         )
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
}
