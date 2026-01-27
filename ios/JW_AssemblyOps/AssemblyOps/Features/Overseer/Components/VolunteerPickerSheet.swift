//
//  VolunteerPickerSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Volunteer Picker Sheet
//
// Modal for selecting a volunteer to assign to a coverage slot.
// Uses the app's design system with warm background and floating cards.
//
// Parameters:
//   - postId: Target post for the assignment
//   - sessionId: Target session for the assignment
//   - onComplete: Callback with success status after assignment
//
// Features:
//   - Warm gradient background
//   - Floating volunteer cards with avatar
//   - Search volunteers by name
//   - Entrance animations
//   - Creates assignment via CreateAssignmentMutation
//

import SwiftUI
import Apollo

struct VolunteerPickerSheet: View {
    let postId: String
    let sessionId: String
    let onComplete: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = VolunteersViewModel()
    @ObservedObject private var sessionState = OverseerSessionState.shared

    @State private var searchText = ""
    @State private var isAssigning = false
    @State private var selectedVolunteer: VolunteerListItem?
    @State private var errorMessage: String?
    @State private var hasAppeared = false

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
            ZStack {
                // Warm background
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()

                Group {
                    if viewModel.isLoading {
                        LoadingView(message: "Loading volunteers...")
                    } else if filteredVolunteers.isEmpty {
                        emptyState
                    } else {
                        volunteerList
                    }
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
                    if isAssigning {
                        ProgressView()
                    } else {
                        Button("Assign") {
                            Task { await assignVolunteer() }
                        }
                        .disabled(selectedVolunteer == nil)
                        .fontWeight(.semibold)
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
        .task {
            if let departmentId = sessionState.selectedDepartment?.id {
                viewModel.departmentId = departmentId
                await viewModel.loadVolunteers()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Spacer()

            Image(systemName: "person.3")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Text("No Volunteers")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("Add volunteers to your department first")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppTheme.Spacing.screenEdge)
        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
    }

    // MARK: - Volunteer List

    private var volunteerList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.m) {
                ForEach(Array(filteredVolunteers.enumerated()), id: \.element.id) { index, volunteer in
                    Button {
                        HapticManager.shared.lightTap()
                        selectedVolunteer = volunteer
                    } label: {
                        VolunteerPickerRow(
                            volunteer: volunteer,
                            isSelected: selectedVolunteer?.id == volunteer.id,
                            colorScheme: colorScheme
                        )
                    }
                    .buttonStyle(.plain)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.02)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.s)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }

    // MARK: - Assign Volunteer

    private func assignVolunteer() async {
        guard let volunteer = selectedVolunteer else { return }

        isAssigning = true
        errorMessage = nil
        HapticManager.shared.lightTap()

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
                HapticManager.shared.success()
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

// MARK: - Volunteer Picker Row

private struct VolunteerPickerRow: View {
    let volunteer: VolunteerListItem
    let isSelected: Bool
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Avatar with initials
            ZStack {
                Circle()
                    .fill(isSelected ? AppTheme.themeColor.opacity(0.15) : AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .frame(width: 44, height: 44)

                Text(volunteer.initials)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? AppTheme.themeColor : AppTheme.textSecondary(for: colorScheme))
            }

            // Volunteer info
            VStack(alignment: .leading, spacing: 4) {
                Text(volunteer.fullName)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)

                Text(volunteer.congregation)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            Spacer()

            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.themeColor)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .strokeBorder(isSelected ? AppTheme.themeColor.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    VolunteerPickerSheet(postId: "1", sessionId: "1") { _ in }
}
