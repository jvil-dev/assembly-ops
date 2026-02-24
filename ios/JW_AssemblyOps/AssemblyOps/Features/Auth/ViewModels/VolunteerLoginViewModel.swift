//
//  VolunteerLoginViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Login View Model
//
// Handles volunteer authentication via GraphQL loginVolunteer mutation.
// Manages form state, validation, loading states, and error handling.
//
// Published Properties:
//   - idPrefix: Event type prefix ("CA" or "RC")
//   - volunteerId: User-entered volunteer ID suffix (e.g., "A7X9K2")
//   - token: User-entered auth token
//   - isLoading: True while login request is in flight
//   - errorMessage: Error text to display (nil on success)
//
// Computed Properties:
//   - fullVolunteerId: Constructed ID with prefix (e.g., "CA-A7X9K2")
//   - isFormValid: True if suffix has 4+ chars and token is non-empty
//
// Methods:
//   - login(): Execute loginVolunteer mutation, store tokens on success
//
// Flow:
//   1. User selects event type prefix (CA/RC) and enters suffix + token
//   2. login() validates form, calls GraphQL mutation with fullVolunteerId
//   3. On success: AppState.didLogin() stores tokens, triggers navigation
//   4. On failure: errorMessage displayed to user
//
// Dependencies:
//   - NetworkClient: Apollo GraphQL client
//   - AppState: Stores tokens and triggers auth state change
//
// Used by: VolunteerLoginView.swift

import Foundation
import SwiftUI
import Combine
import Apollo

@MainActor
final class VolunteerLoginViewModel: ObservableObject {
    @Published var idPrefix: String = "CA"   // Event type prefix: "CA" or "RC"
    @Published var volunteerId: String = ""   // Suffix only (e.g., "A7X9K2")
    @Published var token: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let appState = AppState.shared

    /// Constructs the full volunteer ID: "CA-A7X9K2" or "RC-B3M8P1"
    var fullVolunteerId: String {
        "\(idPrefix)-\(volunteerId.uppercased().trimmingCharacters(in: .whitespaces))"
    }

    var isFormValid: Bool {
        volunteerId.trimmingCharacters(in: .whitespaces).count >= 4 &&
        !token.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    func login() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        let input = AssemblyOpsAPI.LoginEventVolunteerInput(
            volunteerId: fullVolunteerId,
            token: token.trimmingCharacters(in: .whitespaces)
        )

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.LoginVolunteerMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.loginEventVolunteer {
                        let ev = data.eventVolunteer
                        let profile = ev.volunteerProfile
                        let volunteer = VolunteerInfo(
                            id: ev.id,
                            volunteerId: ev.volunteerId,
                            firstName: profile.firstName,
                            lastName: profile.lastName,
                            fullName: "\(profile.firstName) \(profile.lastName)",
                            congregation: profile.congregation.name,
                            appointmentStatus: profile.appointmentStatus.rawValue,
                            eventId: ev.event.id,
                            eventName: ev.event.name,
                            eventVenue: ev.event.venue,
                            eventTheme: ev.event.template.theme,
                            departmentId: ev.department?.id,
                            departmentName: ev.department?.name,
                            departmentType: ev.department?.departmentType.rawValue
                        )
                        self?.appState.didLoginAsVolunteer(
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
