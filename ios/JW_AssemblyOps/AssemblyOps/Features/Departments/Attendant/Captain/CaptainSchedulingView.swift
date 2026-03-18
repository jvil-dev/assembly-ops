//
//  CaptainSchedulingView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/1/26.
//

// MARK: - Captain Scheduling View
//
// Captain's scheduling interface for the attendant department.
// Shows post cards with coverage info, filtered to the captain's assigned areas.
// Uses CoverageMatrixViewModel (same data as overseer) with client-side area filtering.
// Opens the overseer's SlotDetailSheet for managing shifts and assignments.
//
// Architecture:
//   CaptainSchedulingView (session picker + post cards)
//     └─ tap post card → SlotDetailSheet (overseer's, reused as-is)
//          ├─ VolunteerPickerSheet (assign to whole session or shift)
//          └─ CreateShiftSheet (create shifts)
//

import SwiftUI

struct CaptainSchedulingView: View {
    let eventId: String
    let departmentId: String
    let departmentType: String
    let captainAreasBySession: [String: [String]]

    @StateObject private var coverageVM = CoverageMatrixViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var selectedSession: CoverageSession?
    @State private var selectedSlot: CoverageSlot?
    @State private var showError = false

    private var accentColor: Color {
        DepartmentColor.color(for: departmentType)
    }

    /// Area IDs the captain is assigned to for the currently selected session
    private var currentSessionAreaIds: [String] {
        guard let sessionId = selectedSession?.id else { return [] }
        return captainAreasBySession[sessionId] ?? []
    }

    /// Posts filtered to captain's assigned areas for the current session
    private var captainPosts: [CoveragePost] {
        let areaIds = currentSessionAreaIds
        return coverageVM.posts.filter { post in
            guard let areaId = post.areaId else { return false }
            return areaIds.contains(areaId)
        }
    }

    /// Slots for the selected session, filtered to captain's area posts
    private func slotsForSession(_ sessionId: String) -> [CoverageSlot] {
        let areaIds = captainAreasBySession[sessionId] ?? []
        let postIds = Set(coverageVM.posts.filter { post in
            guard let areaId = post.areaId else { return false }
            return areaIds.contains(areaId)
        }.map { $0.id })
        return coverageVM.slots.filter { $0.sessionId == sessionId && postIds.contains($0.postId) }
    }

    var body: some View {
        Group {
            if coverageVM.isLoading && coverageVM.slots.isEmpty {
                LoadingView(message: "captain.scheduling.title".localized)
                    .themedBackground(scheme: colorScheme)
            } else {
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        sessionPicker
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                        if let session = selectedSession {
                            let slots = slotsForSession(session.id)

                            summaryCard(slots: slots)
                                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                            if slots.isEmpty {
                                emptyState
                                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                            } else {
                                postsSection(slots: slots)
                            }
                        }
                    }
                    .screenPadding()
                    .padding(.top, AppTheme.Spacing.l)
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }
                .themedBackground(scheme: colorScheme)
                .refreshable {
                    await coverageVM.loadCoverage()
                }
            }
        }
        .navigationTitle("captain.scheduling.title".localized)
        .sheet(item: $selectedSlot) { slot in
            SlotDetailSheet(initialSlot: slot, viewModel: coverageVM)
        }
        .alert("common.error".localized, isPresented: $showError) {
            Button("common.ok".localized, role: .cancel) {}
        } message: {
            Text(coverageVM.error ?? "")
        }
        .onChange(of: coverageVM.error) { _, newValue in
            if newValue != nil { showError = true }
        }
        .task {
            // Set up session state so SlotDetailSheet and VolunteerPickerSheet work
            sessionState.selectedDepartment = DepartmentSummary(
                id: departmentId,
                name: departmentType.capitalized,
                departmentType: departmentType,
                volunteerCount: 0
            )
            coverageVM.departmentId = departmentId
            await coverageVM.loadCoverage()

            // Auto-select first session that has captain areas
            if selectedSession == nil {
                selectedSession = coverageVM.sessions.first { session in
                    captainAreasBySession[session.id] != nil
                } ?? coverageVM.sessions.first
            }
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
                    ForEach(coverageVM.sessions) { session in
                        Button {
                            withAnimation(AppTheme.quickAnimation) {
                                selectedSession = session
                            }
                            HapticManager.shared.lightTap()
                        } label: {
                            Text(session.name)
                                .font(AppTheme.Typography.subheadline)
                                .fontWeight(selectedSession?.id == session.id ? .semibold : .regular)
                                .padding(.horizontal, AppTheme.Spacing.m)
                                .padding(.vertical, AppTheme.Spacing.s)
                                .background(
                                    selectedSession?.id == session.id
                                        ? accentColor
                                        : AppTheme.cardBackgroundSecondary(for: colorScheme)
                                )
                                .foregroundStyle(
                                    selectedSession?.id == session.id
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

    // MARK: - Summary Card

    private func summaryCard(slots: [CoverageSlot]) -> some View {
        let totalAssigned = slots.reduce(0) { $0 + $1.filled }

        return HStack(spacing: AppTheme.Spacing.xl) {
            statBadge(value: "\(slots.count)", label: "captain.scheduling.posts".localized)
            statBadge(value: "\(totalAssigned)", label: "captain.scheduling.assigned".localized)
        }
        .frame(maxWidth: .infinity)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private func statBadge(value: String, label: String) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(value)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(accentColor)
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
    }

    // MARK: - Posts Section

    private func postsSection(slots: [CoverageSlot]) -> some View {
        VStack(spacing: AppTheme.Spacing.m) {
            ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
                Button {
                    selectedSlot = slot
                    HapticManager.shared.lightTap()
                } label: {
                    postCard(slot: slot)
                }
                .buttonStyle(.plain)
                .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.03 + 0.1)
            }
        }
    }

    // MARK: - Post Card

    private func postCard(slot: CoverageSlot) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Post header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(slot.postName)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)

                    if !slot.shifts.isEmpty {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text("slot.shifts.count".localized(with: slot.shifts.count))
                                .font(AppTheme.Typography.caption)
                        }
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                }

                Spacer()

                // Assigned count badge
                Text("\(slot.filled) \("captain.scheduling.assigned".localized)")
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(statusColor(for: slot))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusBackground(for: slot))
                    .clipShape(Capsule())
            }

            // Assigned volunteers
            if slot.assignments.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 12))
                    Text("captain.scheduling.noAssigned".localized)
                }
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(slot.assignments) { assignment in
                        HStack(spacing: AppTheme.Spacing.s) {
                            ZStack {
                                Circle()
                                    .fill(volunteerColor(assignment).opacity(0.15))
                                    .frame(width: 28, height: 28)

                                Text(initials(for: assignment.volunteer))
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(volunteerColor(assignment))
                            }

                            Text("\(assignment.volunteer.firstName) \(assignment.volunteer.lastName)")
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(.primary)

                            if assignment.canCount {
                                Image(systemName: "number.square.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(accentColor)
                            }

                            Spacer()

                            if assignment.checkIn != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppTheme.StatusColors.accepted)
                            } else if assignment.isPending {
                                Image(systemName: "clock")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppTheme.StatusColors.pending)
                            }
                        }
                    }
                }
            }

            // Post location
            if let post = captainPosts.first(where: { $0.id == slot.postId }),
               let location = post.location, !location.isEmpty {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "mappin")
                        .font(.system(size: 10))
                    Text(location)
                        .font(AppTheme.Typography.caption)
                }
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Text("captain.scheduling.noPosts".localized)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            Text("captain.scheduling.noPostsHint".localized)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xl)
    }

    // MARK: - Helpers

    private func statusColor(for slot: CoverageSlot) -> Color {
        if slot.filled > 0 {
            return AppTheme.StatusColors.accepted
        } else if slot.pendingCount > 0 {
            return AppTheme.StatusColors.pending
        } else {
            return AppTheme.StatusColors.declined
        }
    }

    private func statusBackground(for slot: CoverageSlot) -> Color {
        if slot.filled > 0 {
            return AppTheme.StatusColors.acceptedBackground
        } else if slot.pendingCount > 0 {
            return AppTheme.StatusColors.pendingBackground
        } else {
            return AppTheme.StatusColors.declinedBackground
        }
    }

    private func initials(for volunteer: CoverageVolunteer) -> String {
        let first = volunteer.firstName.prefix(1)
        let last = volunteer.lastName.prefix(1)
        return String(first + last).uppercased()
    }

    private func volunteerColor(_ assignment: CoverageAssignment) -> Color {
        if assignment.checkIn != nil { return AppTheme.StatusColors.accepted }
        if assignment.isPending { return AppTheme.StatusColors.pending }
        return accentColor
    }
}

#Preview {
    NavigationStack {
        CaptainSchedulingView(
            eventId: "1",
            departmentId: "d1",
            departmentType: "ATTENDANT",
            captainAreasBySession: [:]
        )
    }
}
