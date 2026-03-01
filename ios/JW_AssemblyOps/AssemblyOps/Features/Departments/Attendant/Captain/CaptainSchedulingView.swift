//
//  CaptainSchedulingView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/1/26.
//

// MARK: - Captain Scheduling View
//
// Captain's scheduling interface for the attendant department.
// Allows captains to view shifts, manage assignments, and create shifts
// within their department scope.
//
// Features:
//   - Session picker
//   - Shift list with create/delete
//   - Volunteer assignment actions (add, swap, remove)
//

import SwiftUI

struct CaptainSchedulingView: View {
    let eventId: String
    let departmentId: String
    let departmentType: String

    @StateObject private var viewModel = CaptainSchedulingViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showCreateShift = false
    @State private var showError = false
    @State private var assignmentToRemove: ShiftAssignment?
    @State private var showRemoveConfirmation = false
    @State private var shiftToAssign: ShiftItem?

    private var accentColor: Color {
        DepartmentColor.color(for: departmentType)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.sessions.isEmpty {
                LoadingView(message: "captain.scheduling.title".localized)
                    .themedBackground(scheme: colorScheme)
            } else {
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        sessionPicker
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                        if let session = viewModel.selectedSession {
                            shiftsSection(for: session)
                                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                        }
                    }
                    .screenPadding()
                    .padding(.top, AppTheme.Spacing.l)
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }
                .themedBackground(scheme: colorScheme)
                .refreshable {
                    if let session = viewModel.selectedSession {
                        await viewModel.loadShifts(sessionId: session.id)
                    }
                }
            }
        }
        .navigationTitle("captain.scheduling.title".localized)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateShift = true
                    HapticManager.shared.lightTap()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(accentColor)
                }
                .disabled(viewModel.selectedSession == nil)
            }
        }
        .sheet(isPresented: $showCreateShift) {
            if let session = viewModel.selectedSession {
                CaptainCreateShiftSheet(
                    eventId: eventId,
                    sessionId: session.id,
                    sessionName: session.name,
                    viewModel: viewModel
                )
            }
        }
        .sheet(item: $shiftToAssign) { shift in
            CaptainVolunteerPickerSheet(
                eventId: eventId,
                postId: shift.postId,
                sessionId: shift.sessionId,
                shiftId: shift.id,
                departmentType: departmentType,
                volunteers: viewModel.volunteers,
                viewModel: viewModel
            ) {
                // Reload shifts after assignment
                if let session = viewModel.selectedSession {
                    Task {
                        await viewModel.loadShifts(sessionId: session.id)
                    }
                }
            }
        }
        .alert("common.error".localized, isPresented: $showError) {
            Button("common.ok".localized, role: .cancel) {}
        } message: {
            Text(viewModel.error ?? "")
        }
        .onChange(of: viewModel.error) { _, newValue in
            showError = newValue != nil
        }
        .alert("Remove Assignment", isPresented: $showRemoveConfirmation) {
            Button("Cancel", role: .cancel) {
                assignmentToRemove = nil
            }
            Button("Remove", role: .destructive) {
                if let assignment = assignmentToRemove {
                    Task {
                        await viewModel.deleteAssignment(eventId: eventId, assignmentId: assignment.id)
                    }
                }
                assignmentToRemove = nil
            }
        } message: {
            if let assignment = assignmentToRemove {
                Text("Remove \(assignment.volunteerName) from this shift?")
            }
        }
        .task {
            await viewModel.loadSessions(eventId: eventId)
            await viewModel.loadVolunteers(eventId: eventId, departmentId: departmentId)
            await viewModel.loadPosts(departmentId: departmentId)
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Session Picker

    private var sessionPicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "calendar", title: "shift.session".localized)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.s) {
                    ForEach(viewModel.sessions) { session in
                        Button {
                            withAnimation(AppTheme.quickAnimation) {
                                viewModel.selectedSession = session
                            }
                            Task {
                                await viewModel.loadShifts(sessionId: session.id)
                            }
                            HapticManager.shared.lightTap()
                        } label: {
                            Text(session.name)
                                .font(AppTheme.Typography.subheadline)
                                .fontWeight(viewModel.selectedSession?.id == session.id ? .semibold : .regular)
                                .padding(.horizontal, AppTheme.Spacing.m)
                                .padding(.vertical, AppTheme.Spacing.s)
                                .background(
                                    viewModel.selectedSession?.id == session.id
                                        ? accentColor
                                        : AppTheme.cardBackgroundSecondary(for: colorScheme)
                                )
                                .foregroundStyle(
                                    viewModel.selectedSession?.id == session.id
                                        ? .white
                                        : AppTheme.textSecondary(for: colorScheme)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Shifts Section

    private func shiftsSection(for session: EventSessionItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack {
                SectionHeaderLabel(icon: "clock", title: "shift.list.title".localized)
                Spacer()
                Text("\(viewModel.shifts.count) \("shift.count".localized)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            if viewModel.shifts.isEmpty {
                VStack(spacing: AppTheme.Spacing.m) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 36))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text("shift.empty".localized)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Text("captain.scheduling.createHint".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.xl)
            } else {
                ForEach(viewModel.shifts) { shift in
                    captainShiftRow(shift)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Captain Shift Row

    private func captainShiftRow(_ shift: ShiftItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            HStack(spacing: AppTheme.Spacing.m) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(shift.name)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(.primary)
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Text(shift.timeRangeDisplay)
                        if let postName = shift.postName {
                            Text("·")
                            Text(postName)
                        }
                    }
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                    if let createdBy = shift.createdByName {
                        Text("Created by \(createdBy)")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                }

                Spacer()

                Button {
                    Task {
                        await viewModel.deleteShift(id: shift.id, eventId: eventId)
                    }
                } label: {
                    Image(systemName: "trash.circle")
                        .font(.title3)
                        .foregroundStyle(AppTheme.StatusColors.declined)
                }
                .buttonStyle(.plain)
            }

            // Assigned volunteers
            if !shift.assignments.isEmpty {
                VStack(spacing: AppTheme.Spacing.xs) {
                    ForEach(shift.assignments) { assignment in
                        HStack(spacing: AppTheme.Spacing.s) {
                            Image(systemName: assignment.isCheckedIn ? "checkmark.circle.fill" : "person.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(assignment.isCheckedIn ? AppTheme.StatusColors.accepted : AppTheme.textTertiary(for: colorScheme))

                            Text(assignment.volunteerName)
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(.primary)

                            Spacer()

                            Button {
                                assignmentToRemove = assignment
                                showRemoveConfirmation = true
                            } label: {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 16))
                                    .foregroundStyle(AppTheme.StatusColors.declined.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, AppTheme.Spacing.s)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    }
                }
                .padding(.leading, AppTheme.Spacing.xs)
            }

            // Add volunteer button
            Button {
                shiftToAssign = shift
                HapticManager.shared.lightTap()
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 14))
                    Text("captain.scheduling.addVolunteer".localized)
                        .font(AppTheme.Typography.subheadline)
                }
                .foregroundStyle(accentColor)
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.vertical, AppTheme.Spacing.s)
                .background(accentColor.opacity(0.1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Divider()
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

// MARK: - Captain Create Shift Sheet

struct CaptainCreateShiftSheet: View {
    let eventId: String
    let sessionId: String
    let sessionName: String
    @ObservedObject var viewModel: CaptainSchedulingViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var selectedPostId: String?
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var isSubmitting = false

    private var isFormValid: Bool {
        selectedPostId != nil &&
        endTime > startTime
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Session info
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                        SectionHeaderLabel(icon: "calendar", title: "shift.session".localized)
                        Text(sessionName)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundStyle(.primary)
                    }
                    .cardPadding()
                    .themedCard(scheme: colorScheme)

                    // Post picker
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        SectionHeaderLabel(icon: "mappin.and.ellipse", title: "shift.post".localized)

                        if viewModel.posts.isEmpty {
                            Text("shift.noPosts".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppTheme.Spacing.s) {
                                    ForEach(viewModel.posts) { post in
                                        Button {
                                            withAnimation(AppTheme.quickAnimation) {
                                                selectedPostId = post.id
                                            }
                                            HapticManager.shared.lightTap()
                                        } label: {
                                            Text(post.name)
                                                .font(AppTheme.Typography.subheadline)
                                                .fontWeight(selectedPostId == post.id ? .semibold : .regular)
                                                .padding(.horizontal, AppTheme.Spacing.m)
                                                .padding(.vertical, AppTheme.Spacing.s)
                                                .background(
                                                    selectedPostId == post.id
                                                        ? DepartmentColor.color(for: "ATTENDANT")
                                                        : AppTheme.cardBackgroundSecondary(for: colorScheme)
                                                )
                                                .foregroundStyle(
                                                    selectedPostId == post.id
                                                        ? .white
                                                        : AppTheme.textSecondary(for: colorScheme)
                                                )
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .cardPadding()
                    .themedCard(scheme: colorScheme)

                    // Time pickers
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        SectionHeaderLabel(icon: "clock", title: "shift.times".localized)
                        DatePicker("shift.startTime".localized, selection: $startTime, displayedComponents: .hourAndMinute)
                            .font(AppTheme.Typography.body)
                        DatePicker("shift.endTime".localized, selection: $endTime, displayedComponents: .hourAndMinute)
                            .font(AppTheme.Typography.body)

                        if endTime <= startTime {
                            HStack(spacing: AppTheme.Spacing.xs) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(AppTheme.StatusColors.warning)
                                Text("shift.timeError".localized)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.StatusColors.warning)
                            }
                        }
                    }
                    .cardPadding()
                    .themedCard(scheme: colorScheme)

                    // Submit
                    Button {
                        Task { await createShift() }
                    } label: {
                        Group {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text("shift.create".localized)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.ButtonHeight.large)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(.white)
                        .background(isFormValid ? DepartmentColor.color(for: "ATTENDANT") : DepartmentColor.color(for: "ATTENDANT").opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("shift.create".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
            }
        }
    }

    private func createShift() async {
        guard let postId = selectedPostId else { return }
        isSubmitting = true
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        await viewModel.createShift(
            eventId: eventId,
            sessionId: sessionId,
            postId: postId,
            startTime: formatter.string(from: startTime),
            endTime: formatter.string(from: endTime)
        )

        isSubmitting = false

        if viewModel.error == nil {
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        CaptainSchedulingView(eventId: "1", departmentId: "d1", departmentType: "ATTENDANT")
    }
}
