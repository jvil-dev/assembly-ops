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
//   - Warm gradient background with entrance animations
//   - Sessions grouped by date with sticky headers
//   - Session cards showing name and assignment count
//   - Tap session → navigate to SessionDetailView
//   - Create Session + Create Post via toolbar menu
//   - Pull-to-refresh
//
// Navigation:
//   Level 1: Session list (this view)
//   Level 2: SessionDetailView (posts for a session)
//   Level 3: SlotDetailSheet (assign volunteers to a post+session)

import SwiftUI
import Apollo

struct AssignmentsView: View {
    @ObservedObject private var sessionState = OverseerSessionState.shared
    @Environment(\.colorScheme) var colorScheme

    @State private var sessions: [EventSessionItem] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var hasAppeared = false
    @State private var showCreateSession = false

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
            .navigationTitle("Assignments")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        if sessionState.isEventOverseer {
                            Button {
                                showCreateSession = true
                            } label: {
                                Label("session.create".localized, systemImage: "calendar.badge.plus")
                            }

                            Divider()
                        }

                        NavigationLink {
                            DeclinedAssignmentsView()
                        } label: {
                            Label("Declined Assignments", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showCreateSession) {
                CreateSessionSheet()
            }
            .refreshable {
                await loadSessions()
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

    // MARK: - Session List

    private var sessionList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.l, pinnedViews: .sectionHeaders) {
                ForEach(Array(groupedSessions.enumerated()), id: \.element.date) { groupIndex, group in
                    Section {
                        ForEach(Array(group.sessions.enumerated()), id: \.element.id) { index, session in
                            NavigationLink {
                                SessionDetailView(session: session)
                            } label: {
                                sessionCard(session)
                            }
                            .buttonStyle(.plain)
                            .entranceAnimation(
                                hasAppeared: hasAppeared,
                                delay: Double(groupIndex) * 0.05 + Double(index) * 0.03
                            )
                        }
                    } header: {
                        dateHeader(for: group.date)
                    }
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }

    // MARK: - Session Card

    private func sessionCard(_ session: EventSessionItem) -> some View {
        HStack(spacing: AppTheme.Spacing.l) {
            // Session icon
            ZStack {
                Circle()
                    .fill(AppTheme.themeColor.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: sessionIcon(for: session.name))
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.themeColor)
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

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Date Header

    private func dateHeader(for date: Date) -> some View {
        HStack {
            if Calendar.current.isDateInToday(date) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.StatusColors.pending)
                        .frame(width: 8, height: 8)
                    Text("Today")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                }
                Text("• \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            } else if Calendar.current.isDateInTomorrow(date) {
                Text("Tomorrow")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
                Text("• \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            } else {
                Text(date.formatted(date: .complete, time: .omitted))
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

            Button {
                showCreateSession = true
            } label: {
                Label("Create Session", systemImage: "plus.circle")
                    .font(AppTheme.Typography.bodyMedium)
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.themeColor)

            Spacer()
        }
        .padding(AppTheme.Spacing.screenEdge)
        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
    }

    // MARK: - Data

    private var groupedSessions: [(date: Date, sessions: [EventSessionItem])] {
        let grouped = Dictionary(grouping: sessions) { session in
            Calendar.current.startOfDay(for: session.date)
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
