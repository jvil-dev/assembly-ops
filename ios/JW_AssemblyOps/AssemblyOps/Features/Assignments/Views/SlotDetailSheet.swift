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
//   - Add Volunteer: Styled button
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

    @ObservedObject private var sessionState = EventSessionState.shared

    @State private var showVolunteerPicker = false
    @State private var assigningForShiftId: String? // nil = whole session
    @State private var hasAppeared = false
    @State private var assignmentToRemove: CoverageAssignment?
    @State private var showRemoveConfirmation = false
    @State private var showCreateShift = false
    @StateObject private var shiftViewModel = ShiftManagementViewModel()

    // Editable post fields
    @State private var editName = ""
    @State private var editLocation = ""
    @State private var editCategory = ""
    @State private var isSaving = false
    @State private var hasEdits = false

    // Attendant category picker state
    @State private var selectedMain: AttendantMainCategory? = nil
    @State private var selectedSub: String? = nil
    @State private var customSub: String = ""
    @State private var showCustomSub = false

    /// Captains can view but not edit post metadata.
    /// Overseers set claimedDepartment; captains only set selectedDepartment.
    private var canEditPost: Bool {
        sessionState.claimedDepartment != nil
    }

    private var deptColor: Color {
        if let deptType = sessionState.selectedDepartment?.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    private var isAttendantDept: Bool {
        sessionState.selectedDepartment?.departmentType == "ATTENDANT"
    }

    private var isAVDept: Bool {
        ["AUDIO", "VIDEO", "STAGE"].contains(sessionState.selectedDepartment?.departmentType.uppercased() ?? "")
    }

    private var isAudioDept: Bool {
        sessionState.selectedDepartment?.departmentType.uppercased() == "AUDIO"
    }

    private var isVideoDept: Bool {
        sessionState.selectedDepartment?.departmentType.uppercased() == "VIDEO"
    }

    private var isStageDept: Bool {
        sessionState.selectedDepartment?.departmentType.uppercased() == "STAGE"
    }

    private var isMakeupPost: Bool {
        editName.localizedCaseInsensitiveContains("Makeup")
    }

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

                    // Shifts & Assignments card (all departments)
                    shiftsAndAssignmentsCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // Create Shift button (all departments)
                    createShiftButton
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
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
                    if hasEdits && canEditPost {
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
                    shiftId: assigningForShiftId
                ) { success in
                    if success {
                        Task {
                            await viewModel.loadCoverage()
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateShift, onDismiss: {
                Task { await viewModel.loadCoverage() }
            }) {
                CreateShiftSheet(
                    sessionId: slot.sessionId,
                    postId: slot.postId,
                    sessionName: slot.sessionName,
                    postName: slot.postName,
                    viewModel: shiftViewModel
                )
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

                    // Pre-select Attendant category picker from stored string
                    if isAttendantDept, let category = post.category, !category.isEmpty {
                        for main in AttendantMainCategory.allCases {
                            if category == main.rawValue {
                                selectedMain = main
                                break
                            } else if category.hasPrefix("\(main.rawValue) - ") {
                                selectedMain = main
                                let sub = String(category.dropFirst("\(main.rawValue) - ".count))
                                if main.commonSubcategories.contains(sub) {
                                    selectedSub = sub
                                } else {
                                    showCustomSub = true
                                    customSub = sub
                                }
                                break
                            }
                        }
                    }
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
                    .foregroundStyle(deptColor)
                Text("Post Details")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            VStack(spacing: AppTheme.Spacing.m) {
                // Name: read-only for AV departments or non-editors, editable for others
                if isAVDept || !canEditPost {
                    infoRow(label: "Name", value: editName)
                } else {
                    editableField(label: "Name", text: $editName)
                }

                // Location: hidden for Audio/Video, picker for Stage, editable for others
                if canEditPost {
                    if isStageDept {
                        stageLocationPicker
                    } else if !isAudioDept && !isVideoDept {
                        editableField(label: "Location", text: $editLocation, placeholder: "Optional")
                    }
                } else if !isAudioDept && !isVideoDept {
                    let locationValue = editLocation.isEmpty ? "—" : editLocation
                    infoRow(label: "Location", value: locationValue)
                }

                // Category: Attendant has its own picker, AV is read-only, others editable
                if canEditPost {
                    if isAttendantDept {
                        attendantCategoryPicker
                    } else if isAVDept {
                        infoRow(label: "Category", value: editCategory.isEmpty ? "—" : editCategory)
                    } else {
                        editableField(label: "Category", text: $editCategory, placeholder: "Optional")
                    }
                } else {
                    infoRow(label: "Category", value: editCategory.isEmpty ? "—" : editCategory)
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
                        Text("\(slot.filled) assigned")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(slot.filled > 0 ? AppTheme.StatusColors.accepted : AppTheme.StatusColors.warning)
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

    // MARK: - Shifts & Assignments Card

    /// Groups assignments by shiftId. Returns array of (shift, assignments) tuples.
    private var assignmentsByShift: [(shift: CoverageShift?, assignments: [CoverageAssignment])] {
        var groups: [(shift: CoverageShift?, assignments: [CoverageAssignment])] = []

        // Group by defined shifts
        for shift in slot.shifts {
            let shiftAssignments = slot.assignments.filter { $0.shiftId == shift.id }
            groups.append((shift: shift, assignments: shiftAssignments))
        }

        // "Whole Session" group — assignments with no shiftId
        let unshifted = slot.assignments.filter { $0.shiftId == nil }
        if !unshifted.isEmpty || slot.shifts.isEmpty {
            groups.append((shift: nil, assignments: unshifted))
        }

        return groups
    }

    private var shiftsAndAssignmentsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Header
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "clock.arrow.2.circlepath")
                    .foregroundStyle(deptColor)
                Text("slot.shifts.title".localized)
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
                    .foregroundStyle(deptColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(deptColor.opacity(0.1))
                    .clipShape(Capsule())
            }

            // Shift sections
            ForEach(Array(assignmentsByShift.enumerated()), id: \.offset) { _, group in
                shiftSection(shift: group.shift, assignments: group.assignments)
            }

            // Hint when no shifts exist
            if slot.shifts.isEmpty && slot.assignments.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: AppTheme.Spacing.s) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 28))
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        Text("slot.shifts.noAssignments".localized)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        Text("slot.shifts.createHint".localized)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .padding(.vertical, AppTheme.Spacing.l)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Shift Section

    private func shiftSection(shift: CoverageShift?, assignments: [CoverageAssignment]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            // Shift header
            HStack {
                if let shift = shift {
                    Image(systemName: "clock")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(deptColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(shift.name)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundStyle(.primary)
                        Text(shift.timeRangeDisplay)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                } else {
                    Image(systemName: "calendar")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Text("slot.shifts.wholeSession".localized)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(.primary)
                }

                Spacer()

                if shift != nil {
                    // Delete shift
                    Button {
                        if let shift = shift {
                            Task { await deleteShift(shift) }
                        }
                    } label: {
                        Image(systemName: "trash.circle")
                            .font(.title3)
                            .foregroundStyle(AppTheme.StatusColors.declined)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Assignments for this shift
            if assignments.isEmpty {
                Text("slot.shifts.noAssignments".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    .padding(.leading, AppTheme.Spacing.l)
            } else {
                ForEach(assignments) { assignment in
                    AssignmentRow(assignment: assignment, colorScheme: colorScheme, accentColor: deptColor)
                        .contextMenu {
                            if isAttendantDept {
                                Button {
                                    Task { await toggleCanCount(assignment) }
                                } label: {
                                    Label(
                                        assignment.canCount ? "assignment.canCount.unmark".localized : "assignment.canCount.mark".localized,
                                        systemImage: assignment.canCount ? "number.square.fill" : "number.square"
                                    )
                                }
                            }
                            Button(role: .destructive) {
                                assignmentToRemove = assignment
                                showRemoveConfirmation = true
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                }
            }

            // Per-shift assign button
            Button {
                assigningForShiftId = shift?.id
                showVolunteerPicker = true
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "plus.circle")
                        .font(AppTheme.Typography.caption)
                    Text("slot.shifts.assignToShift".localized)
                        .font(AppTheme.Typography.caption)
                }
                .foregroundStyle(deptColor)
                .padding(.leading, AppTheme.Spacing.l)
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.top, AppTheme.Spacing.xs)
        }
    }

    // MARK: - Create Shift Button

    private var createShiftButton: some View {
        Button {
            showCreateShift = true
            HapticManager.shared.lightTap()
        } label: {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "plus.circle.fill")
                Text("shift.create".localized)
            }
            .font(AppTheme.Typography.headline)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.ButtonHeight.medium)
            .foregroundStyle(.white)
            .background(deptColor)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Shift Actions

    private func deleteShift(_ shift: CoverageShift) async {
        do {
            try await AttendantService.shared.deleteShift(id: shift.id)
            HapticManager.shared.success()
            await viewModel.loadCoverage()
        } catch {
            HapticManager.shared.error()
        }
    }

    // MARK: - Attendant Category Picker

    private var attendantCategoryPicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            Text("Category")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            // Step 1: Main category pills (I / E / S)
            HStack(spacing: AppTheme.Spacing.s) {
                ForEach(AttendantMainCategory.allCases) { main in
                    Button {
                        if selectedMain == main {
                            selectedMain = nil
                            selectedSub = nil
                            showCustomSub = false
                            customSub = ""
                            editCategory = ""
                            checkForEdits()
                        } else {
                            selectedMain = main
                            selectedSub = nil
                            showCustomSub = false
                            customSub = ""
                            syncCategory()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(main.code)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                            Text(main.rawValue)
                                .font(AppTheme.Typography.caption)
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)
                        .padding(.vertical, AppTheme.Spacing.s)
                        .background(selectedMain == main
                            ? deptColor
                            : AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .foregroundStyle(selectedMain == main ? .white : AppTheme.textSecondary(for: colorScheme))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            // Step 2: Subcategory chips (only for Exterior)
            if let main = selectedMain, !main.commonSubcategories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.s) {
                        ForEach(main.commonSubcategories, id: \.self) { sub in
                            Button {
                                selectedSub = sub
                                showCustomSub = false
                                customSub = ""
                                syncCategory()
                            } label: {
                                Text(sub)
                                    .font(AppTheme.Typography.caption)
                                    .padding(.horizontal, AppTheme.Spacing.m)
                                    .padding(.vertical, AppTheme.Spacing.s)
                                    .background(selectedSub == sub
                                        ? deptColor.opacity(0.2)
                                        : AppTheme.cardBackgroundSecondary(for: colorScheme))
                                    .foregroundStyle(selectedSub == sub
                                        ? deptColor
                                        : AppTheme.textSecondary(for: colorScheme))
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(selectedSub == sub
                                                ? deptColor
                                                : Color.clear, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        // Custom chip
                        Button {
                            selectedSub = nil
                            showCustomSub = true
                            syncCategory()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Custom")
                                    .font(AppTheme.Typography.caption)
                            }
                            .padding(.horizontal, AppTheme.Spacing.m)
                            .padding(.vertical, AppTheme.Spacing.s)
                            .background(showCustomSub
                                ? deptColor.opacity(0.2)
                                : AppTheme.cardBackgroundSecondary(for: colorScheme))
                            .foregroundStyle(showCustomSub
                                ? deptColor
                                : AppTheme.textSecondary(for: colorScheme))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(showCustomSub
                                        ? deptColor
                                        : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if showCustomSub {
                    TextField("e.g. Gate, Ramp B", text: $customSub)
                        .padding(AppTheme.Spacing.m)
                        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                        .onChange(of: customSub) { _, _ in syncCategory() }
                }
            }
        }
    }

    // MARK: - Stage Location Picker

    private var stageLocationPicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            Text("Location")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            HStack(spacing: AppTheme.Spacing.s) {
                ForEach(["Stage Right", "Stage Left", "Backstage"], id: \.self) { option in
                    Button {
                        editLocation = editLocation == option ? "" : option
                        checkForEdits()
                    } label: {
                        Text(option)
                            .font(AppTheme.Typography.caption)
                            .padding(.horizontal, AppTheme.Spacing.m)
                            .padding(.vertical, AppTheme.Spacing.s)
                            .background(editLocation == option
                                ? deptColor
                                : AppTheme.cardBackgroundSecondary(for: colorScheme))
                            .foregroundStyle(editLocation == option
                                ? .white
                                : AppTheme.textSecondary(for: colorScheme))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func syncCategory() {
        guard let main = selectedMain else {
            editCategory = ""
            checkForEdits()
            return
        }
        let sub: String?
        if showCustomSub {
            sub = customSub.isEmpty ? nil : customSub
        } else {
            sub = selectedSub
        }
        editCategory = AttendantMainCategory.storageString(main: main, sub: sub)
        checkForEdits()
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

    private func toggleCanCount(_ assignment: CoverageAssignment) async {
        let input = AssemblyOpsAPI.SetCanCountInput(
            assignmentId: assignment.id,
            canCount: !assignment.canCount
        )
        do {
            let _ = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.SetCanCountMutation(input: input)
            )
            HapticManager.shared.success()
            await viewModel.loadCoverage()
        } catch {
            HapticManager.shared.error()
        }
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

#Preview {
    SlotDetailSheet(
        initialSlot: CoverageSlot(
            postId: "p1", sessionId: "s1",
            postName: "Main Entrance", sessionName: "Morning Session",
            shifts: [],
            assignments: [], filled: 2
        ),
        viewModel: CoverageMatrixViewModel()
    )
}

// MARK: - Assignment Row

struct AssignmentRow: View {
    let assignment: CoverageAssignment
    let colorScheme: ColorScheme
    var accentColor: Color = AppTheme.themeColor

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
        return accentColor
    }
}
