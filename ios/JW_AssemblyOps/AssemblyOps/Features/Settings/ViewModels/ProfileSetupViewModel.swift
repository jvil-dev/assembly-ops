//
//  ProfileSetupViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/31/26.
//

// MARK: - Overseer Profile Setup View Model
//
// Manages the mandatory profile completion flow for new overseers.
// Validates form and calls updateUserProfile mutation to persist.
//
// Properties:
//   - firstName, lastName, phone: Form fields (pre-filled from login)
//   - congregationName, congregationId: Set by CongregationSearchField
//
// Flow:
//   1. On appear: pre-fill name from AppState
//   2. User searches and selects congregation via CongregationSearchField
//   3. User taps Continue -> calls updateUserProfile mutation
//   4. On success -> updates AppState with new profile data
//

import Foundation
import Apollo
import Combine

@MainActor
final class ProfileSetupViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var phone: String = ""
    @Published var congregationName: String = ""
    @Published var congregationId: String?

    @Published var isSaving = false
    @Published var errorMessage: String?

    private let appState = AppState.shared

    var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        congregationId != nil
    }

    /// Pre-fill form fields from current user info
    func prefill() {
        if let user = appState.currentUser {
            firstName = user.firstName
            lastName = user.lastName
            phone = user.phone ?? ""
        }
    }

    // MARK: - Save Profile

    func saveProfile() {
        guard isFormValid, let congId = congregationId else { return }

        isSaving = true
        errorMessage = nil

        let input = AssemblyOpsAPI.UpdateUserProfileInput(
            firstName: .some(firstName.trimmingCharacters(in: .whitespaces)),
            lastName: .some(lastName.trimmingCharacters(in: .whitespaces)),
            phone: phone.isEmpty ? .none : .some(phone.trimmingCharacters(in: .whitespaces)),
            congregationId: .some(congId)
        )

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.UpdateUserProfileMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.updateUserProfile {
                        if let current = self?.appState.currentUser {
                            self?.appState.currentUser = UserInfo(
                                id: current.id,
                                userId: current.userId,
                                email: current.email,
                                firstName: data.firstName,
                                lastName: data.lastName,
                                fullName: data.fullName,
                                phone: data.phone,
                                congregation: data.congregation,
                                congregationId: data.congregationId,
                                circuitCode: data.congregationRef?.circuit.code,
                                circuitId: data.congregationRef?.circuit.id,
                                appointmentStatus: current.appointmentStatus,
                                isOverseer: current.isOverseer
                            )
                        }
                        HapticManager.shared.success()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.localizedDescription ?? "Failed to save profile"
                        HapticManager.shared.error()
                    }
                case .failure(let error):
                    self?.errorMessage = "Unable to save. Please check your connection."
                    print("Profile save error: \(error)")
                    HapticManager.shared.error()
                }
                self?.isSaving = false
            }
        }
    }
}
