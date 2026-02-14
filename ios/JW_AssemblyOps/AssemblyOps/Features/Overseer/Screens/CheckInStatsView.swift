//
//  CheckInStatsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/9/26.
//

// MARK: - Check-In Stats View
//
// Screen displaying volunteer check-in statistics across all event sessions.
// Provides oversight of volunteer attendance and participation rates.
//
// Features:
//   - Lists all event sessions with check-in metrics
//   - Shows assigned vs checked-in volunteer counts
//   - Displays completion percentage with color-coded progress bar
//   - Includes attendance count when available
//   - Pull-to-refresh to update statistics
//   - Empty state when no check-in data exists
//
// Navigation:
//   - Accessed from OverseerDashboardView or OverseerMessagesView
//   - Provides read-only view of check-in status

import SwiftUI

struct CheckInStatsView: View {
    @StateObject private var viewModel = CheckInStatsViewModel()
    @StateObject private var attendanceVM = AttendanceViewModel()
    @ObservedObject private var sessionState: OverseerSessionState = .shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            // Background
            AppTheme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.stats.isEmpty {
                LoadingView(message: "Loading stats...")
            } else if viewModel.stats.isEmpty {
                emptyState
            } else {
                statsList
            }
        }
        .navigationTitle("Check-In Stats")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await loadData()
        }
        .task {
            await loadData()
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                HapticManager.shared.lightTap()
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Spacer()

            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Text("No Stats Available")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("Check-in statistics will appear here")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppTheme.Spacing.screenEdge)
        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
    }

    // MARK: - Stats List
    private var statsList: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Overall summary card
                if viewModel.stats.count > 1 {
                    overallSummaryCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                }

                // Per-session stats
                ForEach(Array(viewModel.stats.enumerated()), id: \.element.id) { index, stats in
                    CheckInStatsCard(stats: stats)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index + 1) * 0.05)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }

    // MARK: - Overall Summary Card
    private var overallSummaryCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "chart.bar")
                    .foregroundStyle(AppTheme.themeColor)
                Text("OVERALL SUMMARY")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Totals
            HStack(spacing: AppTheme.Spacing.m) {
                statColumn(value: totalCheckedIn, label: "Total Checked In", color: .green)
                statColumn(value: totalCheckedOut, label: "Total Left", color: .blue)
                statColumn(value: totalNoShow, label: "Total No Show", color: .red)
                statColumn(value: totalPending, label: "Total Pending", color: .orange)
            }

            // Overall rate
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Overall Attendance Rate")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Spacer()
                    Text("\(Int(overallAttendanceRate * 100))%")
                        .font(AppTheme.Typography.captionBold)
                        .foregroundStyle(AppTheme.themeColor)
                }
                ProgressView(value: overallAttendanceRate)
                    .tint(AppTheme.themeColor)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private func statColumn(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(AppTheme.Typography.title)
                .foregroundStyle(color)
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed Properties
    private var totalCheckedIn: Int {
        viewModel.stats.reduce(0) { $0 + $1.checkedIn }
    }

    private var totalCheckedOut: Int {
        viewModel.stats.reduce(0) { $0 + $1.checkedOut }
    }

    private var totalNoShow: Int {
        viewModel.stats.reduce(0) { $0 + $1.noShow }
    }

    private var totalPending: Int {
        viewModel.stats.reduce(0) { $0 + $1.pending }
    }

    private var totalAssignments: Int {
        viewModel.stats.reduce(0) { $0 + $1.totalAssignments }
    }

    private var overallAttendanceRate: Double {
        guard totalAssignments > 0 else { return 0 }
        return Double(totalCheckedIn + totalCheckedOut) / Double(totalAssignments)
    }

    // MARK: - Data Loading
    private func loadData() async {
        guard let eventId = sessionState.selectedEvent?.id else { return }

        // Load attendance summary to get session data
        await attendanceVM.loadEventSummary(eventId: eventId)

        // Build session names dictionary and load stats
        let sessionNames = Dictionary(uniqueKeysWithValues: attendanceVM.sessionSummaries.map {
            ($0.sessionId, $0.sessionName)
        })
        let sessionIds = attendanceVM.sessionSummaries.map { $0.sessionId }

        await viewModel.loadStats(sessionIds: sessionIds, sessionNames: sessionNames)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        CheckInStatsView()
    }
}
