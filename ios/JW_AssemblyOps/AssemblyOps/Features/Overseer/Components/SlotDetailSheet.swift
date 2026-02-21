//
//  SlotDetailSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Slot Detail Sheet
//
// Modal view showing details for a coverage matrix slot (post + session).
// Uses the app's design system with warm background and floating cards.
//
// Sections:
//   - Slot Info: Post name, session name, coverage count
//   - Assigned Volunteers: List of current assignments with check-in status
//   - Add Volunteer: Styled button (if not at capacity)
//
// Features:
//   - Warm gradient background
//   - Floating cards with themed styling
//   - Entrance animations
//

import SwiftUI

struct SlotDetailSheet: View {
    let initialSlot: CoverageSlot
    @ObservedObject var viewModel: CoverageMatrixViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var showVolunteerPicker = false
    @State private var hasAppeared = false
    @State private var assignmentToRemove: CoverageAssignment?
    @State private var showRemoveConfirmation = false

    // Editable post fields
    @State private var editName = ""
    @State private var editLocation = ""
    @State private var editCategory = ""
    @State private var editCapacity = 1
    @State private var isSaving = false
    @State private var hasEdits = false

    /// Live slot from viewModel, falls back to initial snapshot
    private var slot: CoverageSlot {
        viewModel.slot(for: initialSlot.postId, session: initialSlot.sessionId) ?? initialSlot
    }

    private var post: CoveragePost? {
        viewModel.posts.first(where: { $0.id == initialSlot.postId })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Slot info card
                    slotInfoCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Assigned volunteers card
                    volunteersCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // Add volunteer button
                    if slot.filled < slot.capacity {
                        addVolunteerButton
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                    }
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("Slot Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if hasEdits {
                        Button {
                            Task { await savePostEdits() }
                        } label: {
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("Save")
                                    .fontWeight(.semibold)
                            }
                        }
                        .disabled(editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                    } else {
                        Button("Done") { dismiss() }
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showVolunteerPicker) {
                VolunteerPickerSheet(
                    postId: slot.postId,
                    sessionId: slot.sessionId,
                    remainingCapacity: max(slot.capacity - slot.filled, 1)
                ) { success in
                    if success {
                        Task {
                            await viewModel.loadCoverage()
                        }
                    }
                }
            }
            .alert("Remove Assignment", isPresented: $showRemoveConfirmation) {
                Button("Cancel", role: .cancel) {
                    assignmentToRemove = nil
                }
                Button("Remove", role: .destructive) {
                    if let assignment = assignmentToRemove {
                        Task { await deleteAssignment(assignment) }
                    }
                }
            } message: {
                if let assignment = assignmentToRemove {
                    Text("Remove \(assignment.volunteer.firstName) \(assignment.volunteer.lastName) from this assignment?")
                }
            }
            .onAppear {
                if let post {
                    editName = post.name
                    editLocation = post.location ?? ""
                    editCategory = post.category ?? ""
                    editCapacity = post.capacity
                }
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Slot Info Card

    private var slotInfoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Header
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "tablecells")
                    .foregroundStyle(AppTheme.themeColor)
                Text("Post Details")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            VStack(spacing: AppTheme.Spacing.m) {
                editableField(label: "Name", text: $editName)
                editableField(label: "Location", text: $editLocation, placeholder: "Optional")
                editableField(label: "Category", text: $editCategory, placeholder: "Optional")

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Capacity")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Picker("Capacity", selection: $editCapacity) {
                        ForEach(1...20, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                    .onChange(of: editCapacity) { checkForEdits() }
                }

                // Session (read-only)
                infoRow(label: "Session", value: slot.sessionName)

                // Coverage (read-only)
                HStack {
                    Text("Coverage")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(slot.filled)/\(slot.capacity)")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(slot.isFilled ? AppTheme.StatusColors.accepted : AppTheme.StatusColors.warning)
                        if slot.pendingCount > 0 {
                            Text("(\(slot.pendingCount) pending)")
                                .font(AppTheme.Typography.captionSmall)
                                .foregroundStyle(AppTheme.StatusColors.pending)
                        }
                    }
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Volunteers Card

    private var volunteersCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Header
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("Assigned Volunteers")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

                Spacer()

                if slot.pendingCount > 0 {
                    Text("\(slot.pendingCount) pending")
                        .font(AppTheme.Typography.captionBold)
                        .foregroundStyle(AppTheme.StatusColors.pending)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.StatusColors.pendingBackground)
                        .clipShape(Capsule())
                }

                Text("\(slot.assignments.count)")
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(AppTheme.themeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.themeColor.opacity(0.1))
                    .clipShape(Capsule())
            }

            if slot.assignments.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: AppTheme.Spacing.s) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 28))
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        Text("No volunteers assigned")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                    Spacer()
                }
                .padding(.vertical, AppTheme.Spacing.l)
            } else {
                List {
                    ForEach(slot.assignments) { assignment in
                        AssignmentRow(assignment: assignment, colorScheme: colorScheme)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(
                                top: AppTheme.Spacing.s / 2,
                                leading: 0,
                                bottom: AppTheme.Spacing.s / 2,
                                trailing: 0
                            ))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    assignmentToRemove = assignment
                                    showRemoveConfirmation = true
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(minHeight: CGFloat(slot.assignments.count) * 60)
                .scrollDisabled(true)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Add Volunteer Button

    private var addVolunteerButton: some View {
        Button {
            showVolunteerPicker = true
        } label: {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "plus.circle.fill")
                Text("Assign Volunteer")
            }
            .font(AppTheme.Typography.headline)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.ButtonHeight.medium)
            .foregroundStyle(.white)
            .background(AppTheme.themeColor)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func deleteAssignment(_ assignment: CoverageAssignment) async {
        do {
            let _ = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.DeleteAssignmentMutation(id: assignment.id)
            )
            HapticManager.shared.success()
            await viewModel.loadCoverage()
        } catch {
            HapticManager.shared.error()
        }
        assignmentToRemove = nil
    }

    private func editableField(label: String, text: Binding<String>, placeholder: String = "") -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            TextField("", text: text)
                .font(AppTheme.Typography.bodyMedium)
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                .onChange(of: text.wrappedValue) { checkForEdits() }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            Spacer()

            Text(value)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundStyle(.primary)
        }
    }

    private func checkForEdits() {
        guard let post else { hasEdits = false; return }
        hasEdits = editName != post.name
            || editLocation != (post.location ?? "")
            || editCategory != (post.category ?? "")
            || editCapacity != post.capacity
    }

    private func savePostEdits() async {
        guard let post else { return }
        isSaving = true
        defer { isSaving = false }

        let trimmedName = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = editLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = editCategory.trimmingCharacters(in: .whitespacesAndNewlines)

        let input = AssemblyOpsAPI.UpdatePostInput(
            name: trimmedName != post.name ? .some(trimmedName) : .none,
            location: trimmedLocation != (post.location ?? "") ? (trimmedLocation.isEmpty ? .null : .some(trimmedLocation)) : .none,
            capacity: editCapacity != post.capacity ? .some(editCapacity) : .none,
            category: trimmedCategory != (post.category ?? "") ? (trimmedCategory.isEmpty ? .null : .some(trimmedCategory)) : .none
        )

        do {
            let _ = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.UpdatePostMutation(id: post.id, input: input)
            )
            HapticManager.shared.success()
            await viewModel.loadCoverage()
            hasEdits = false
        } catch {
            HapticManager.shared.error()
        }
    }
}

// MARK: - Assignment Row

struct AssignmentRow: View {
    let assignment: CoverageAssignment
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Avatar
            ZStack {
                Circle()
                    .fill(avatarColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Text(initials)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(avatarColor)
            }

            // Name and status
            VStack(alignment: .leading, spacing: 2) {
                Text("\(assignment.volunteer.firstName) \(assignment.volunteer.lastName)")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundStyle(.primary)

                if let checkIn = assignment.checkIn {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text("Checked in \(checkIn.checkInTime, style: .time)")
                    }
                    .font(AppTheme.Typography.captionSmall)
                    .foregroundStyle(AppTheme.StatusColors.accepted)
                } else if assignment.isPending {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("assignment.status.pending".localized)
                    }
                    .font(AppTheme.Typography.captionSmall)
                    .foregroundStyle(AppTheme.StatusColors.pending)
                }
            }

            Spacer()

            // Right-side status indicator
            if assignment.checkIn != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.StatusColors.accepted)
            } else if assignment.isPending {
                AssignmentStatusBadgeCompact(status: .pending)
            }
        }
        .padding(AppTheme.Spacing.s)
        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
    }

    private var initials: String {
        let first = assignment.volunteer.firstName.prefix(1)
        let last = assignment.volunteer.lastName.prefix(1)
        return String(first + last).uppercased()
    }

    private var avatarColor: Color {
        if assignment.checkIn != nil { return AppTheme.StatusColors.accepted }
        if assignment.isPending { return AppTheme.StatusColors.pending }
        return AppTheme.themeColor
    }
}
