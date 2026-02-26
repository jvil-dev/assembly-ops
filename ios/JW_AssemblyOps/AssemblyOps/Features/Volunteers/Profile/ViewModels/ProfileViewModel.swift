//
//  ProfileViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/3/26.
//

// MARK: - Profile View Model
//
// Manages volunteer profile data for the unified-auth user (currentUser in AppState).
// Builds the Volunteer display model directly from AppState — no network call on load.
// Saves phone updates via UpdateUserProfileMutation.
//
// Published Properties:
//   - volunteer: Volunteer profile data (nil until loaded)
//   - errorMessage: Error message if save fails
//   - hasLoaded: True after fetchProfile() is called
//   - isEditing: Whether the user is currently editing their profile
//   - editPhone: Editable copy of phone number
//   - isSaving: Whether a save is in progress
//
// Methods:
//   - fetchProfile(): Builds profile from AppState.shared.currentUser
//   - refresh(): Re-builds profile from AppState
//   - startEditing(): Copies current phone to edit field
//   - cancelEditing(): Discards edit state
//   - saveProfile(): Sends UpdateUserProfileMutation (phone only)
//
// Dependencies:
//   - NetworkClient: Apollo client for GraphQL
//   - AppState: Source of truth for user info
//   - Volunteer: Profile data model
//
// Used by: ProfileView.swift

import Foundation
import SwiftUI
import Combine
import Apollo

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var volunteer: Volunteer?
    @Published var errorMessage: String?
    @Published var hasLoaded = false
    @Published var isEditing = false
    @Published var isSaving = false
    @Published var editPhone: String = ""

    func fetchProfile() {
        errorMessage = nil
        guard let user = AppState.shared.currentUser else {
            errorMessage = "No user session found. Please sign in again."
            hasLoaded = true
            return
        }
        volunteer = Volunteer(
            id: user.id,
            volunteerId: user.userId,
            firstName: user.firstName,
            lastName: user.lastName,
            congregation: user.congregation ?? "",
            phone: user.phone,
            email: user.email,
            appointmentStatus: user.appointmentStatus,
            departmentId: nil,
            departmentName: nil,
            departmentType: nil,
            eventId: nil,
            eventName: nil,
            eventVenue: nil,
            eventAddress: nil,
            eventStartDate: nil,
            eventEndDate: nil
        )
        hasLoaded = true
    }

    func refresh() {
        fetchProfile()
    }

    func startEditing() {
        editPhone = volunteer?.phone ?? ""
        isEditing = true
    }

    func cancelEditing() {
        isEditing = false
        editPhone = ""
    }

    func saveProfile() {
        guard isEditing else { return }
        isSaving = true
        errorMessage = nil

        let trimmedPhone = editPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        let input = AssemblyOpsAPI.UpdateUserProfileInput(
            phone: trimmedPhone.isEmpty ? .null : .some(trimmedPhone)
        )

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.UpdateUserProfileMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isSaving = false
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        self.errorMessage = errors.first?.localizedDescription ?? "Failed to update profile"
                        HapticManager.shared.error()
                    } else if let data = graphQLResult.data?.updateUserProfile {
                        if let user = AppState.shared.currentUser {
                            AppState.shared.currentUser = UserInfo(
                                id: user.id, userId: user.userId, email: user.email,
                                firstName: user.firstName, lastName: user.lastName,
                                fullName: user.fullName,
                                phone: data.phone,
                                congregation: data.congregation,
                                congregationId: user.congregationId,
                                appointmentStatus: user.appointmentStatus,
                                isOverseer: user.isOverseer
                            )
                        }
                        self.isEditing = false
                        HapticManager.shared.success()
                        self.fetchProfile()
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    HapticManager.shared.error()
                }
            }
        }
    }
}
