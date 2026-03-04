//
//  AssignmentsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Assignments View (Overseer)
//
// Session-based navigation for overseers to manage volunteer scheduling.
// Shows sessions grouped by date; tap a session to see posts and assignments.
//
// Features:
//   - Inline header with "Schedule" title and "Declined" link
//   - Sessions grouped by date with sticky headers
//   - Session cards showing name and assignment count
//   - Tap session → navigate to SessionDetailView
//   - Dashed "Create Session" box at bottom of list
//   - Drag-to-reorder sessions within date groups
//   - Pull-to-refresh
//
// Navigation:
//   Level 1: Session list (this view)
//   Level 2: SessionDetailView (posts for a session)
//   Level 3: SlotDetailSheet (assign volunteers to a post+session)

import SwiftUI
import Apollo

struct AssignmentsView: View {
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme

    @State private var sessions: [EventSessionItem] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var hasAppeared = false
    @State private var showCreateSession = false
    @State private var isReorderMode = false
    @State private var sessionToDelete: EventSessionItem?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && sessions.isEmpty {
                    LoadingView(message: "Loading sessions...")
                } else if sessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
            .themedBackground(scheme: colorScheme)
            .sheet(isPresented: $showCreateSession) {
                CreateSessionSheet()
            }
            .onChange(of: showCreateSession) { _, isPresented in
                if !isPresented {
                    Task { await loadSessions() }
                }
            }
            .refreshable {
                await loadSessions()
            }
            .alert("schedule.deleteSessionConfirm".localized, isPresented: $showDeleteConfirmation) {
                Button("common.cancel".localized, role: .cancel) {
                    sessionToDelete = nil
                }
                Button("common.delete".localized, role: .destructive) {
                    if let session = sessionToDelete {
                        Task { await deleteSession(session) }
                    }
                }
            } message: {
                if let session = sessionToDelete {
                    Text(String(format: "schedule.deleteSessionWarning".localized, session.name))
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
        .task {
            if sessions.isEmpty, sessionState.selectedEvent?.id != nil {
                await loadSessions()
            }
        }
    }

    // MARK: - Inline Header

    private var inlineHeader: some View {
        HStack {
            Text("schedule.header".localized)
                .font(AppTheme.Typography.title)
                .foregroundStyle(.primary)

            Spacer()

            if isReorderMode {
                Button {
                    withAnimation(AppTheme.quickAnimation) {
                        isReorderMode = false
                    }
                    HapticManager.shared.lightTap()
                } label: {
                    Text("schedule.done".localized)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(deptColor)
                }
            } else {
                HStack(spacing: AppTheme.Spacing.l) {
                    Button {
                        withAnimation(AppTheme.quickAnimation) {
                            isReorderMode = true
                        }
                        HapticManager.shared.lightTap()
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }

                    NavigationLink {
                        DeclinedAssignmentsView()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 14, weight: .medium))
                            Text("schedule.declined".localized)
                                .font(AppTheme.Typography.bodyMedium)
                        }
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                }
            }
        }
        .padding(.bottom, AppTheme.Spacing.s)
    }

    // MARK: - Session List

    @ViewBuilder
    private var sessionList: some View {
        if isReorderMode {
            reorderableSessionList
        } else {
            normalSessionList
        }
    }

    private var normalSessionList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.l, pinnedViews: .sectionHeaders) {
                inlineHeader
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                ForEach(Array(groupedSessions.enumerated()), id: \.element.date) { groupIndex, group in
                    Section {
                        ForEach(Array(group.sessions.enumerated()), id: \.element.id) { index, session in
                            NavigationLink {
                                SessionDetailView(session: session)
                            } label: {
                                sessionCard(session)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    sessionToDelete = session
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("schedule.deleteSession".localized, systemImage: "trash")
                                }
                            }
                            .entranceAnimation(
                                hasAppeared: hasAppeared,
                                delay: Double(groupIndex) * 0.05 + Double(index) * 0.03
                            )
                        }
                    } header: {
                        dateHeader(for: group.date)
                    }
                }

                createSessionBox
                    .entranceAnimation(
                        hasAppeared: hasAppeared,
                        delay: Double(groupedSessions.count) * 0.05 + 0.05
                    )
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }

    // MARK: - Reorderable Session List

    private var reorderableSessionList: some View {
        VStack(spacing: 0) {
            // Inline header above the list
            inlineHeader
                .padding(.horizontal, AppTheme.Spacing.screenEdge)
                .padding(.top, AppTheme.Spacing.l)

            List {
                ForEach(groupedSessions, id: \.date) { group in
                    Section {
                        ForEach(group.sessions) { session in
                            HStack(spacing: AppTheme.Spacing.m) {
                                ZStack {
                                    Circle()
                                        .fill(deptColor.opacity(0.12))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: sessionIcon(for: session.name))
                                        .font(.system(size: 16))
                                        .foregroundStyle(deptColor)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.name)
                                        .font(AppTheme.Typography.bodyMedium)
                                        .foregroundStyle(.primary)
                                    Text("\(session.assignmentCount) assignments")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                                }
                            }
                            .padding(.vertical, AppTheme.Spacing.xs)
                        }
                        .onMove { source, destination in
                            moveSession(in: group.date, from: source, to: destination)
                        }
                    } header: {
                        Text(dateHeaderText(for: group.date))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, .constant(.active))
            .tint(deptColor)
        }
    }

    // MARK: - Create Session Box

    private var createSessionBox: some View {
        Button {
            showCreateSession = true
            HapticManager.shared.lightTap()
        } label: {
            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(deptColor.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(deptColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("schedule.createSession".localized)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Text("schedule.createSessionHint".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                Spacer()

                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 20))
                    .foregroundStyle(deptColor)
            }
            .cardPadding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .strokeBorder(
                        deptColor.opacity(0.3),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Department Color

    private var deptColor: Color {
        if let deptType = sessionState.selectedDepartment?.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    // MARK: - Session Card

    private func sessionCard(_ session: EventSessionItem) -> some View {
        HStack(spacing: AppTheme.Spacing.l) {
            // Session icon
            ZStack {
                Circle()
                    .fill(deptColor.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: sessionIcon(for: session.name))
                    .font(.system(size: 20))
                    .foregroundStyle(deptColor)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(session.name)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: AppTheme.Spacing.s) {
                    Label("\(session.assignmentCount) assignments", systemImage: "person.2")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
            }

            Spacer()

            if !isReorderMode {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Date Header

    private func dateHeader(for date: Date) -> some View {
        HStack {
            if DateUtils.isSessionDateToday(date) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.StatusColors.pending)
                        .frame(width: 8, height: 8)
                    Text("Today")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                }
                Text("• \(DateUtils.formatSessionDateAbbreviated(date))")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            } else if DateUtils.isSessionDateTomorrow(date) {
                Text("Tomorrow")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
                Text("• \(DateUtils.formatSessionDateAbbreviated(date))")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            } else {
                Text(DateUtils.formatSessionDateFull(date))
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.s)
        .padding(.horizontal, AppTheme.Spacing.xs)
    }

    // MARK: - Helpers

    private func sessionIcon(for name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("morning") { return "sun.max.fill" }
        if lower.contains("noon") { return "sun.min.fill" }
        return "sun.haze.fill"
    }

    // MARK: - Reorder Logic

    private func moveSession(in date: Date, from source: IndexSet, to destination: Int) {
        let dateKey = DateUtils.sessionStartOfDay(for: date)

        // Get the sorted sessions for this date group
        let groupSessions = sessions
            .filter { DateUtils.sessionStartOfDay(for: $0.date) == dateKey }
            .sorted { $0.startTime < $1.startTime }

        // Collect the original startTimes in order
        let originalStartTimes = groupSessions.map(\.startTime)

        // Build reordered ID list
        var reorderedIds = groupSessions.map(\.id)
        reorderedIds.move(fromOffsets: source, toOffset: destination)

        // Assign the original startTimes to the new positions
        for (newIndex, sessionId) in reorderedIds.enumerated() {
            guard let flatIndex = sessions.firstIndex(where: { $0.id == sessionId }) else { continue }
            sessions[flatIndex] = EventSessionItem(
                id: sessions[flatIndex].id,
                name: sessions[flatIndex].name,
                date: sessions[flatIndex].date,
                startTime: originalStartTimes[newIndex],
                assignmentCount: sessions[flatIndex].assignmentCount
            )
        }
        HapticManager.shared.lightTap()
    }

    private func dateHeaderText(for date: Date) -> String {
        if DateUtils.isSessionDateToday(date) {
            return "Today — \(DateUtils.formatSessionDateAbbreviated(date))"
        } else if DateUtils.isSessionDateTomorrow(date) {
            return "Tomorrow — \(DateUtils.formatSessionDateAbbreviated(date))"
        }
        return DateUtils.formatSessionDateFull(date)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Text("No Sessions Yet")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("Sessions are created automatically when an event is activated. You can also create custom sessions.")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            // Dashed create box in empty state
            createSessionBox

            Spacer()
        }
        .padding(AppTheme.Spacing.screenEdge)
        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
    }

    // MARK: - Data

    private var groupedSessions: [(date: Date, sessions: [EventSessionItem])] {
        let grouped = Dictionary(grouping: sessions) { session in
            DateUtils.sessionStartOfDay(for: session.date)
        }
        return grouped
            .map { (date: $0.key, sessions: $0.value.sorted { $0.startTime < $1.startTime }) }
            .sorted { $0.date < $1.date }
    }

    private func loadSessions() async {
        guard let eventId = sessionState.selectedEvent?.id else { return }

        isLoading = true
        error = nil

        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.EventSessionsQuery(eventId: eventId),
                cachePolicy: .fetchIgnoringCacheData
            )

            guard let data = result.data?.sessions else {
                error = "Failed to load sessions"
                isLoading = false
                return
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let fallback = ISO8601DateFormatter()

            sessions = data.map { session in
                EventSessionItem(
                    id: session.id,
                    name: session.name,
                    date: formatter.date(from: session.date) ?? fallback.date(from: session.date) ?? Date(),
                    startTime: formatter.date(from: session.startTime) ?? fallback.date(from: session.startTime) ?? Date(),
                    assignmentCount: session.assignmentCount
                )
            }

        } catch {
            self.error = "Network error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func deleteSession(_ session: EventSessionItem) async {
        do {
            let _ = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.DeleteSessionMutation(id: session.id)
            )
            HapticManager.shared.success()
            sessions.removeAll { $0.id == session.id }
        } catch {
            self.error = "Failed to delete session"
            HapticManager.shared.error()
        }
        sessionToDelete = nil
    }
}

// MARK: - Event Session Item

struct EventSessionItem: Identifiable {
    let id: String
    let name: String
    let date: Date
    let startTime: Date
    let assignmentCount: Int
}

#Preview {
    AssignmentsView()
}

#Preview("Dark Mode") {
    AssignmentsView()
        .preferredColorScheme(.dark)
}
