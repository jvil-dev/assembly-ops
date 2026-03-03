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
//   - onComplete: Callback with success status after assignment
//
// Features:
//   - Warm gradient background
//   - Floating volunteer cards with avatar
//   - Multi-select
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
    var shiftId: String? = nil
    let onComplete: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = VolunteersViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared

    private var deptColor: Color {
        if let deptType = sessionState.selectedDepartment?.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    @State private var searchText = ""
    @State private var isAssigning = false
    @State private var selectedIds: Set<String> = []
    @State private var errorMessage: String?
    @State private var hasAppeared = false
    @State private var forceAssign = false
    @State private var canCount = false
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

                if isAttendantDepartment {
                    canCountCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.02)
                }

                ForEach(Array(filteredVolunteers.enumerated()), id: \.element.id) { index, volunteer in
                    let isSelected = selectedIds.contains(volunteer.id)
                    Button {
                        HapticManager.shared.lightTap()
                        if isSelected {
                            selectedIds.remove(volunteer.id)
                        } else {
                            selectedIds.insert(volunteer.id)
                        }
                    } label: {
                        VolunteerPickerRow(
                            volunteer: volunteer,
                            isSelected: isSelected,
                            colorScheme: colorScheme,
                            accentColor: deptColor
                        )
                    }
                    .buttonStyle(.plain)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index + 1) * 0.02)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.s)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }

    private var isAttendantDepartment: Bool {
        sessionState.selectedDepartment?.departmentType == "ATTENDANT"
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
        .tint(deptColor)
        .onChange(of: forceAssign) {
            HapticManager.shared.lightTap()
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Can Count Card

    private var canCountCard: some View {
        Toggle(isOn: $canCount) {
            VStack(alignment: .leading, spacing: 2) {
                Text("assignment.canCount.toggle".localized)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundStyle(.primary)
                Text("assignment.canCount.subtitle".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .tint(deptColor)
        .onChange(of: canCount) {
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

            let shiftIdParam: GraphQLNullable<String> = shiftId.map { .some($0) } ?? .none

            if forceAssign {
                // Force assign requires sequential calls (no bulk endpoint)
                var allSucceeded = true
                for volunteerId in selectedIds {
                    let input = AssemblyOpsAPI.ForceAssignmentInput(
                        volunteerId: volunteerId,
                        postId: postId,
                        sessionId: sessionId,
                        shiftId: shiftIdParam,
                        canCount: .some(canCount)
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
                    sessionId: sessionId,
                    shiftId: shiftIdParam,
                    canCount: .some(canCount)
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
                        sessionId: sessionId,
                        shiftId: shiftIdParam,
                        canCount: .some(canCount)
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
    let colorScheme: ColorScheme
    var accentColor: Color = AppTheme.themeColor

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Avatar with initials
            ZStack {
                Circle()
                    .fill(isSelected ? accentColor.opacity(0.15) : AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .frame(width: 44, height: 44)

                Text(volunteer.initials)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? accentColor : AppTheme.textSecondary(for: colorScheme))
            }

            // Volunteer info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(volunteer.fullName)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)

                Text(volunteer.congregation)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            Spacer()

            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundStyle(isSelected ? accentColor : AppTheme.textTertiary(for: colorScheme))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .strokeBorder(isSelected ? accentColor.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    VolunteerPickerSheet(postId: "1", sessionId: "1") { _ in }
}
