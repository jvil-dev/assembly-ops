//
//  VolunteerPickerSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Volunteer Picker Sheet
//
// Modal for selecting a volunteer to assign to a coverage slot.
// Presented from SlotDetailSheet when adding assignments.
//
// Parameters:
//   - postId: Target post for the assignment
//   - sessionId: Target session for the assignment
//   - onComplete: Callback with success status after assignment
//
// Features:
//   - Search volunteers by name
//   - Single-selection with visual checkmark
//   - Creates assignment via CreateAssignmentMutation
//   - Loads volunteers from current department
//
// Flow:
//   1. Load department volunteers on appear
//   2. User searches and selects volunteer
//   3. Tap Assign → CreateAssignmentMutation
//   4. On success: Dismiss and trigger coverage refresh
//

import SwiftUI
import Apollo

struct VolunteerPickerSheet: View {
    let postId: String
    let sessionId: String
    let onComplete: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VolunteersViewModel()
    @ObservedObject private var sessionState = OverseerSessionState.shared
    @State private var searchText = ""
    @State private var isAssigning = false
    @State private var selectedVolunteer: VolunteerListItem?
    @State private var errorMessage: String?

    var filteredVolunteers: [VolunteerListItem] {
        if searchText.isEmpty {
            return viewModel.volunteers
        }
        return viewModel.volunteers.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading volunteers...")
                } else if filteredVolunteers.isEmpty {
                    ContentUnavailableView(
                        "No Volunteers",
                        systemImage: "person.3",
                        description: Text("Add volunteers to your department first")
                    )
                } else {
                    volunteerList
                }
            }
            .searchable(text: $searchText, prompt: "Search volunteers")
            .navigationTitle("Select Volunteer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Assign") {
                        Task { await assignVolunteer() }
                    }
                    .disabled(selectedVolunteer == nil || isAssigning)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .task {
            if let departmentId = sessionState.selectedDepartment?.id {
                viewModel.departmentId = departmentId
                await viewModel.loadVolunteers()
            }
        }
    }

    private var volunteerList: some View {
        List(filteredVolunteers) { volunteer in
            Button {
                selectedVolunteer = volunteer
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(volunteer.fullName)
                        Text(volunteer.congregation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if selectedVolunteer?.id == volunteer.id {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color("ThemeColor"))
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func assignVolunteer() async {
        guard let volunteer = selectedVolunteer else { return }

        isAssigning = true
        errorMessage = nil

        do {
            let input = AssemblyOpsAPI.CreateAssignmentInput(
                volunteerId: volunteer.id,
                postId: postId,
                sessionId: sessionId
            )

            let result = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.CreateAssignmentMutation(input: input)
            )

            if result.data?.createAssignment != nil {
                onComplete(true)
                dismiss()
            } else if let errors = result.errors, !errors.isEmpty {
                errorMessage = errors.first?.message ?? "Failed to create assignment"
            }
        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
        }

        isAssigning = false
    }
}
