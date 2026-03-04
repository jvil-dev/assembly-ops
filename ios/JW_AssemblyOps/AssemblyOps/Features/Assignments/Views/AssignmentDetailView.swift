//
//  AssignmentDetailView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Assignment Detail View
//
// Full-screen detail view for a single assignment.
// Uses the app's design system with warm background and floating cards.
//
// Features:
//   - Warm gradient background
//   - Floating header card with post info
//   - Detailed info section with icons
//   - Accept/Decline buttons for pending assignments (iOS 26 glass effect)
//   - Check-in controls for accepted assignments
//   - Captain group roster (if applicable)
//   - Staggered entrance animations
//

import SwiftUI

struct AssignmentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: AssignmentDetailViewModel
    @StateObject private var attendantVM = AttendantVolunteerViewModel()
    let assignment: Assignment
    let onUpdate: () -> Void

    @State private var showDeclineSheet = false
    @State private var declineReason = ""
    @State private var hasAppeared = false
    @State private var areaGroup: AreaGroupItem?
    @State private var isLoadingAreaGroup = false

    init(assignment: Assignment, onUpdate: @escaping () -> Void = {}) {
        self.assignment = assignment
        self.onUpdate = onUpdate
        _viewModel = StateObject(wrappedValue: AssignmentDetailViewModel(assignment: assignment))
    }

    private var isAttendantAccepted: Bool {
        assignment.isAccepted && assignment.departmentType == "ATTENDANT"
    }

    private var isAttendantCounter: Bool {
        isAttendantAccepted && assignment.canCount
    }

    private var isAttendantCaptain: Bool {
        assignment.isCaptain && assignment.isAccepted && assignment.departmentType == "ATTENDANT"
    }

    private var isSeatingPost: Bool {
        assignment.postCategory?.hasPrefix("Seating") == true
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Header card
                headerCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                // Details card
                detailsCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                // Accept/Decline for pending
                if assignment.canRespond {
                    acceptDeclineSection
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                }

                // Check-in for accepted
                if assignment.isAccepted {
                    checkInCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                }

                // Attendant sections (designated counters only)
                if isAttendantCounter {
                    attendantSectionsCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)

                    // Attendance count history
                    if !attendantVM.postCountHistory.isEmpty {
                        attendanceHistoryCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.18)
                    }

                    // Seating status toggle (seating posts only)
                    if isSeatingPost {
                        seatingSectionStatusCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.19)
                    }
                }

                // Captain group (if captain — not applicable to AV departments)
                if assignment.isCaptain && assignment.isAccepted && !assignment.isAVDepartment {
                    captainGroupCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.2)
                }

                // Post incident summary (Attendant captains only)
                if isAttendantCaptain {
                    postIncidentSummaryCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.25)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("Assignment")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
        .task {
            if isAttendantCounter {
                await attendantVM.loadPostCountHistory(postId: assignment.postId)
                if isSeatingPost {
                    await attendantVM.loadPostSessionStatuses(sessionId: assignment.sessionId)
                }
            }
            if isAttendantCaptain {
                async let concerns: () = attendantVM.loadConcerns(eventId: assignment.eventId)
                async let areaGroupLoad: () = loadAreaGroup()
                _ = await (concerns, areaGroupLoad)
            }
        }
        .sheet(isPresented: $showDeclineSheet) {
            DeclineReasonSheet(reason: $declineReason) {
                Task {
                    await viewModel.declineAssignment(reason: declineReason.isEmpty ? nil : declineReason)
                    dismiss()
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Post name and status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(assignment.postName)
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(.primary)

                    // Department with color
                    HStack(spacing: 6) {
                        Circle()
                            .fill(assignment.departmentColor)
                            .frame(width: 10, height: 10)
                        Text(assignment.departmentName)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                }

                Spacer()

                AssignmentStatusBadge(
                    status: assignment.status,
                    isCaptain: assignment.isCaptain,
                    departmentType: assignment.departmentType
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
            Text("Details")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(assignment.departmentColor)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                DetailRow(
                    icon: "calendar",
                    title: "Date",
                    value: DateUtils.formatSessionDateFull(assignment.date),
                    colorScheme: colorScheme,
                    accentColor: assignment.departmentColor
                )

                DetailRow(
                    icon: "clock",
                    title: "Time",
                    value: assignment.timeRangeFormatted,
                    colorScheme: colorScheme,
                    accentColor: assignment.departmentColor
                )

                if let location = assignment.postLocation {
                    DetailRow(
                        icon: "mappin",
                        title: "Location",
                        value: location,
                        colorScheme: colorScheme,
                        accentColor: assignment.departmentColor
                    )
                }

                DetailRow(
                    icon: "person.2",
                    title: "Session",
                    value: assignment.sessionName,
                    colorScheme: colorScheme,
                    accentColor: assignment.departmentColor
                )

                if let shiftName = assignment.shiftName, assignment.hasShift {
                    DetailRow(
                        icon: "clock.arrow.2.circlepath",
                        title: "Shift",
                        value: shiftName,
                        colorScheme: colorScheme,
                        accentColor: assignment.departmentColor
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Accept/Decline Section

    private var acceptDeclineSection: some View {
        AcceptDeclineButtons(
            assignment: assignment,
            onAccept: {
                Task {
                    await viewModel.acceptAssignment()
                    dismiss()
                }
            },
            onDecline: {
                showDeclineSheet = true
            }
        )
    }

    // MARK: - Check-in Card

    private var checkInCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "clock.badge.checkmark", title: "assignment.checkIn".localized)

            CheckInButton(
                assignment: assignment,
                onCheckIn: {
                    Task {
                        await viewModel.checkIn()
                        onUpdate()
                    }
                },
                onCheckOut: {
                    Task {
                        await viewModel.checkOut()
                        onUpdate()
                    }
                }
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Attendant Post Actions Card

    @State private var attendanceCount: Int = 0
    @State private var attendanceNotes: String = ""
    @State private var showCountSubmitted = false
    @State private var showAttendanceError = false

    private var attendantSectionsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "number.square", title: "attendant.detail.submitCount".localized)

            // Post info
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "mappin")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                VStack(alignment: .leading, spacing: 2) {
                    Text(assignment.postName)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(.primary)
                    if let location = assignment.postLocation {
                        Text(location)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                }
                Spacer()
                Text(assignment.sessionName)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            // Count picker
            Picker("", selection: $attendanceCount) {
                ForEach(0...500, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
            .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

            // Notes (optional)
            TextField("attendant.attendance.notes.placeholder".localized, text: $attendanceNotes)
                .font(AppTheme.Typography.body)
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

            // Submit button
            Button {
                Task {
                    await attendantVM.submitPostCount(
                        postId: assignment.postId,
                        postName: assignment.postName,
                        sessionId: assignment.sessionId,
                        count: attendanceCount,
                        notes: attendanceNotes.isEmpty ? nil : attendanceNotes
                    )
                    if attendantVM.error == nil {
                        showCountSubmitted = true
                        await attendantVM.loadPostCountHistory(postId: assignment.postId)
                    }
                }
            } label: {
                HStack(spacing: AppTheme.Spacing.s) {
                    if attendantVM.isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("attendant.attendance.submit".localized)
                    }
                }
                .font(AppTheme.Typography.bodyMedium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.m)
                .background(attendanceCount > 0 ? assignment.departmentColor : AppTheme.textTertiary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
            }
            .buttonStyle(.plain)
            .disabled(attendanceCount == 0 || attendantVM.isSaving)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .alert("attendant.attendance.submitted".localized, isPresented: $showCountSubmitted) {
            Button("common.ok".localized) {
                attendanceCount = 0
                attendanceNotes = ""
            }
        }
        .onChange(of: attendantVM.error) { _, newValue in showAttendanceError = newValue != nil }
        .alert("common.error".localized, isPresented: $showAttendanceError) {
            Button("common.ok".localized) { attendantVM.error = nil }
        } message: {
            Text(attendantVM.error ?? "")
        }
    }

    // MARK: - Attendance History Card

    private var attendanceHistoryCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "clock.arrow.circlepath", title: "assignment.attendance.history".localized)

            ForEach(attendantVM.postCountHistory) { entry in
                HStack(spacing: AppTheme.Spacing.m) {
                    Text("\(entry.count)")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.themeColor)
                        .frame(width: 50, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.sessionName)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(.primary)
                        Text(entry.updatedAt, style: .relative)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }

                    Spacer()

                    if let notes = entry.notes, !notes.isEmpty {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Seating Section Status Card

    private var currentSectionStatus: SeatingSectionStatusItem {
        attendantVM.postSessionStatuses
            .first(where: { $0.postId == assignment.postId && $0.sessionId == assignment.sessionId })?
            .status ?? .open
    }

    private var seatingSectionStatusCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "chair.lounge", title: "attendant.seating.title".localized)

            Text("attendant.seating.subtitle".localized)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            HStack(spacing: AppTheme.Spacing.s) {
                ForEach(SeatingSectionStatusItem.allCases, id: \.rawValue) { status in
                    Button {
                        Task {
                            await attendantVM.updateSectionStatus(
                                postId: assignment.postId,
                                sessionId: assignment.sessionId,
                                status: status
                            )
                        }
                        HapticManager.shared.lightTap()
                    } label: {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: status.icon)
                            Text(status.displayName)
                        }
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(currentSectionStatus == status ? .semibold : .regular)
                        .foregroundStyle(currentSectionStatus == status ? .white : status.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.m)
                        .background(currentSectionStatus == status ? status.color : status.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                    }
                    .buttonStyle(.plain)
                    .disabled(attendantVM.isSaving)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Post Incident Summary Card (Attendant Captains)

    private var postIncidentSummaryCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(AppTheme.StatusColors.warning)
                Text("attendant.captain.postIncidents.title".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            let unresolvedIncidents: [SafetyIncidentItem] = {
                if let group = areaGroup {
                    let postIds = Set(group.members.map { $0.postId })
                    return attendantVM.unresolvedIncidents(forPostIds: postIds)
                }
                return attendantVM.unresolvedIncidents(for: assignment.postId)
            }()

            if unresolvedIncidents.isEmpty {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.StatusColors.accepted)
                    Text("attendant.captain.postIncidents.allClear".localized)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
            } else {
                ForEach(unresolvedIncidents.prefix(3)) { incident in
                    NavigationLink(destination: VolunteerConcernDetailView(concern: .incident(incident))) {
                        incidentSummaryRow(incident)
                    }
                    .buttonStyle(.plain)
                }
                if unresolvedIncidents.count > 3 {
                    Text("+ \(unresolvedIncidents.count - 3) more")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private func incidentSummaryRow(_ incident: SafetyIncidentItem) -> some View {
        HStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: incident.type.icon)
                .foregroundStyle(AppTheme.StatusColors.warning)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(incident.type.displayName)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.primary)
                Text(incident.description)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                .font(.caption)
        }
    }

    // MARK: - Captain Group Card

    private var captainGroupCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Your Group")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(assignment.departmentColor)
            }

            if isAttendantCaptain {
                AreaCaptainGroupContent(
                    group: areaGroup,
                    isLoading: isLoadingAreaGroup,
                    onCheckIn: onUpdate
                )
            } else {
                CaptainGroupView(
                    postId: assignment.postId,
                    sessionId: assignment.sessionId,
                    onCheckIn: onUpdate
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Load Area Group

    private func loadAreaGroup() async {
        isLoadingAreaGroup = true
        if let groups = try? await AreaService.shared.fetchMyAreaGroups() {
            areaGroup = groups.first { $0.sessionId == assignment.sessionId }
        }
        isLoadingAreaGroup = false
    }
}

// MARK: - Detail Row

private struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let colorScheme: ColorScheme
    var accentColor: Color = AppTheme.themeColor

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(accentColor)
                .frame(width: 24, height: 24)

            // Title
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .frame(width: 70, alignment: .leading)

            // Value
            Text(value)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        AssignmentDetailView(assignment: .preview)
    }
    .environmentObject(AppState.shared)
}

#Preview("Pending") {
    NavigationStack {
        AssignmentDetailView(assignment: .previewPending)
    }
    .environmentObject(AppState.shared)
}

#Preview("Captain") {
    NavigationStack {
        AssignmentDetailView(assignment: .previewCaptain)
    }
    .environmentObject(AppState.shared)
}

#Preview("Dark Mode") {
    NavigationStack {
        AssignmentDetailView(assignment: .previewPending)
    }
    .preferredColorScheme(.dark)
    .environmentObject(AppState.shared)
}
