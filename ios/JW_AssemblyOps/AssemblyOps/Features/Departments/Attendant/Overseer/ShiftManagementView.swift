//
//  ShiftManagementView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/1/26.
//

// MARK: - Shift Management View
//
// Overseer view for managing shifts within sessions.
// Shows a session picker and the list of shifts for the selected session.
// Supports creating, editing, and deleting shifts.
//
// Features:
//   - Session picker (horizontal scroll)
//   - Shift list with time range display
//   - Create shift via sheet
//   - Swipe-to-delete shifts
//   - Pull-to-refresh
//

import SwiftUI

struct ShiftManagementView: View {
    @StateObject private var viewModel = ShiftManagementViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var editingShift: ShiftItem?
    @State private var showError = false
    @State private var assignmentToRemove: ShiftAssignment?
    @State private var showRemoveConfirmation = false

    private var accentColor: Color {
        if let deptType = sessionState.selectedDepartment?.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.sessions.isEmpty {
                LoadingView(message: "shift.management.title".localized)
                    .themedBackground(scheme: colorScheme)
            } else {
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        sessionPicker
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                        if let session = viewModel.selectedSession {
                            shiftsList(for: session)
                                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                        } else {
                            noSessionSelected
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
        .navigationTitle("shift.management.title".localized)
        .toolbar {
            // Create-new is disabled — shifts are now created per-post from Slot Detail
            ToolbarItem(placement: .primaryAction) {
                EmptyView()
            }
        }
        .sheet(item: $editingShift) { shift in
            CreateShiftSheet(
                sessionId: shift.sessionId,
                postId: shift.postId,
                sessionName: viewModel.selectedSession?.name ?? "",
                postName: shift.postName,
                viewModel: viewModel,
                editingShift: shift
            )
        }
        .alert("common.error".localized, isPresented: $showError) {
            Button("common.ok".localized, role: .cancel) {}
        } message: {
            Text(viewModel.error ?? "")
        }
        .onChange(of: viewModel.error) { newValue in
            showError = newValue != nil
        }
        .alert("Remove Assignment", isPresented: $showRemoveConfirmation) {
            Button("Cancel", role: .cancel) {
                assignmentToRemove = nil
            }
            Button("Remove", role: .destructive) {
                if let assignment = assignmentToRemove {
                    Task {
                        await viewModel.deleteAssignment(id: assignment.id)
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
            guard let eventId = sessionState.selectedEvent?.id else { return }
            await viewModel.loadSessions(eventId: eventId)
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

    // MARK: - Shifts List

    private func shiftsList(for session: EventSessionItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack {
                SectionHeaderLabel(icon: "clock", title: "shift.list.title".localized)
                Spacer()
                Text("\(viewModel.shifts.count) \("shift.count".localized)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            if viewModel.shifts.isEmpty {
                emptyShiftsView
            } else {
                ForEach(viewModel.shifts) { shift in
                    shiftRow(shift)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Shift Row

    private func shiftRow(_ shift: ShiftItem) -> some View {
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

                HStack(spacing: AppTheme.Spacing.m) {
                    Button {
                        editingShift = shift
                        HapticManager.shared.lightTap()
                    } label: {
                        Image(systemName: "pencil.circle")
                            .font(.title3)
                            .foregroundStyle(accentColor)
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task {
                            await viewModel.deleteShift(id: shift.id)
                            HapticManager.shared.success()
                        }
                    } label: {
                        Image(systemName: "trash.circle")
                            .font(.title3)
                            .foregroundStyle(AppTheme.StatusColors.declined)
                    }
                    .buttonStyle(.plain)
                }
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

            Divider()
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }

    // MARK: - Empty State

    private var emptyShiftsView: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Text("shift.empty".localized)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            Text("shift.empty.hint".localized)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xl)
    }

    // MARK: - No Session Selected

    private var noSessionSelected: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Text("shift.noSession".localized)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxl)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }
}

#Preview {
    NavigationStack {
        ShiftManagementView()
    }
}
