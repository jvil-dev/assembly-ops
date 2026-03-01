//
//  VolunteerPickerSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Volunteer Picker Sheet
//
// Modal for selecting volunteers to assign to a coverage slot.
// Uses the app's design system with warm background and floating cards.
//
// Parameters:
//   - postId: Target post for the assignment
//   - sessionId: Target session for the assignment
//   - remainingCapacity: Max number of volunteers that can be selected
//   - onComplete: Callback with success status after assignment
//
// Features:
//   - Warm gradient background
//   - Floating volunteer cards with avatar
//   - Multi-select with capacity limit
//   - Search volunteers by name
//   - Entrance animations
//   - Default: creates PENDING assignments via BulkCreateAssignmentsMutation
//   - Force Assign toggle: creates ACCEPTED assignments via ForceAssignmentMutation (sequential)
//

import SwiftUI
import Apollo

struct VolunteerPickerSheet: View {
    let postId: String
    let sessionId: String
    var remainingCapacity: Int = 1
    let onComplete: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = VolunteersViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared

    @State private var searchText = ""
    @State private var isAssigning = false
    @State private var selectedIds: Set<String> = []
    @State private var errorMessage: String?
    @State private var hasAppeared = false
    @State private var forceAssign = false
    @State private var showError = false

    var filteredVolunteers: [VolunteerListItem] {
        if searchText.isEmpty {
            return viewModel.volunteers
        }
        return viewModel.volunteers.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var selectionCount: Int { selectedIds.count }
    private var atCapacity: Bool { selectionCount >= remainingCapacity }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Loading volunteers...")
                } else if filteredVolunteers.isEmpty {
                    emptyState
                } else {
                    volunteerList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .themedBackground(scheme: colorScheme)
            .searchable(text: $searchText, prompt: "Search volunteers")
            .navigationTitle("Select Volunteers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isAssigning {
                        ProgressView()
                    } else {
                        Button(selectionCount > 1 ? "Assign (\(selectionCount))" : "Assign") {
                            Task { await assignVolunteers() }
                        }
                        .disabled(selectedIds.isEmpty)
                        .fontWeight(.semibold)
                    }
                }
            }
            .onChange(of: errorMessage) { _, newValue in showError = newValue != nil }
            .alert("common.error".localized, isPresented: $showError) {
                Button("common.ok".localized) { errorMessage = nil }
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
                forceAssignCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                if remainingCapacity > 1 {
                    capacityInfoCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.01)
                }

                ForEach(Array(filteredVolunteers.enumerated()), id: \.element.id) { index, volunteer in
                    let isSelected = selectedIds.contains(volunteer.id)
                    Button {
                        HapticManager.shared.lightTap()
                        if isSelected {
                            selectedIds.remove(volunteer.id)
                        } else if !atCapacity {
                            selectedIds.insert(volunteer.id)
                        }
                    } label: {
                        VolunteerPickerRow(
                            volunteer: volunteer,
                            isSelected: isSelected,
                            isDisabled: !isSelected && atCapacity,
                            colorScheme: colorScheme
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isSelected && atCapacity)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index + 1) * 0.02)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.s)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }

    // MARK: - Capacity Info Card

    private var capacityInfoCard: some View {
        HStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(AppTheme.themeColor)

            Text("\(selectionCount)/\(remainingCapacity) slots selected")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            Spacer()

            if selectionCount > 0 {
                Button {
                    HapticManager.shared.lightTap()
                    selectedIds.removeAll()
                } label: {
                    Text("Clear")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.themeColor)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Force Assign Card

    private var forceAssignCard: some View {
        Toggle(isOn: $forceAssign) {
            VStack(alignment: .leading, spacing: 2) {
                Text("assignment.forceAssign.toggle".localized)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundStyle(.primary)
                Text("assignment.forceAssign.subtitle".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .tint(AppTheme.themeColor)
        .onChange(of: forceAssign) {
            HapticManager.shared.lightTap()
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Assign Volunteers

    private func assignVolunteers() async {
        guard !selectedIds.isEmpty else { return }

        isAssigning = true
        errorMessage = nil
        HapticManager.shared.lightTap()

        do {
            var success = false

            if forceAssign {
                // Force assign requires sequential calls (no bulk endpoint)
                var allSucceeded = true
                for volunteerId in selectedIds {
                    let input = AssemblyOpsAPI.ForceAssignmentInput(
                        volunteerId: volunteerId,
                        postId: postId,
                        sessionId: sessionId
                    )
                    let result = try await NetworkClient.shared.apollo.perform(
                        mutation: AssemblyOpsAPI.ForceAssignmentMutation(input: input)
                    )
                    if result.data?.forceAssignment == nil {
                        if let errors = result.errors, !errors.isEmpty {
                            errorMessage = errors.first?.message ?? "Failed to create assignment"
                            allSucceeded = false
                            break
                        }
                    }
                }
                success = allSucceeded
            } else if selectedIds.count == 1 {
                // Single selection uses the original mutation
                let volunteerId = selectedIds.first!
                let input = AssemblyOpsAPI.CreateAssignmentInput(
                    volunteerId: volunteerId,
                    postId: postId,
                    sessionId: sessionId
                )
                let result = try await NetworkClient.shared.apollo.perform(
                    mutation: AssemblyOpsAPI.CreateAssignmentMutation(input: input)
                )
                if result.data?.createAssignment != nil {
                    success = true
                } else if let errors = result.errors, !errors.isEmpty {
                    errorMessage = errors.first?.message ?? "Failed to create assignment"
                }
            } else {
                // Multi-selection uses bulk mutation
                let inputs = selectedIds.map { volunteerId in
                    AssemblyOpsAPI.CreateAssignmentInput(
                        volunteerId: volunteerId,
                        postId: postId,
                        sessionId: sessionId
                    )
                }
                let result = try await NetworkClient.shared.apollo.perform(
                    mutation: AssemblyOpsAPI.BulkCreateAssignmentsMutation(inputs: inputs)
                )
                if let data = result.data?.bulkCreateAssignments, !data.isEmpty {
                    success = true
                } else if let errors = result.errors, !errors.isEmpty {
                    errorMessage = errors.first?.message ?? "Failed to create assignments"
                }
            }

            if success {
                HapticManager.shared.success()
                onComplete(true)
                dismiss()
            }
        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
            HapticManager.shared.error()
        }

        isAssigning = false
    }
}

// MARK: - Volunteer Picker Row

private struct VolunteerPickerRow: View {
    let volunteer: VolunteerListItem
    let isSelected: Bool
    var isDisabled: Bool = false
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
            .opacity(isDisabled ? 0.4 : 1)

            // Volunteer info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(volunteer.fullName)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)

                Text(volunteer.congregation)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
            .opacity(isDisabled ? 0.4 : 1)

            Spacer()

            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundStyle(isSelected ? AppTheme.themeColor : AppTheme.textTertiary(for: colorScheme))
                .opacity(isDisabled ? 0.3 : 1)
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
    VolunteerPickerSheet(postId: "1", sessionId: "1", remainingCapacity: 3) { _ in }
}
