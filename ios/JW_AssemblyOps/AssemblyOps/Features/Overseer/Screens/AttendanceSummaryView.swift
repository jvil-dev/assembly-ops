//
//  AttendanceSummaryView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/8/26.
//

// MARK: - Attendance Summary View
//
// Screen displaying aggregated attendance counts across all event sessions.
// Provides an event-wide overview of attendance data with section breakdowns.
//
// Features:
//   - Lists all event sessions with attendance data
//   - Shows total count per session
//   - Expandable section breakdown for detailed counts
//   - Displays submitter name and timestamp for each count
//   - Pull-to-refresh to update data
//   - Empty state when no attendance has been logged
//
// Navigation:
//   - Accessed from OverseerDashboardView via "View Summary" button
//   - Works in conjunction with AttendanceInputView for data entry

import SwiftUI

struct AttendanceSummaryView: View {
    @StateObject private var viewModel = AttendanceViewModel()
    @ObservedObject private var sessionState: OverseerSessionState = .shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showError = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading attendance...")
            } else {
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        totalBannerCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                        ForEach(Array(viewModel.sessionSummaries.enumerated()), id: \.element.id) { index, summary in
                            sessionCard(summary)
                                .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index + 1) * 0.05)
                        }
                    }
                    .screenPadding()
                    .padding(.top, AppTheme.Spacing.l)
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }
            }
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("Attendance Summary")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            if let eventId = sessionState.selectedEvent?.id {
                await viewModel.loadEventSummary(eventId: eventId)
            }
        }
        .task {
            if let eventId = sessionState.selectedEvent?.id {
                await viewModel.loadEventSummary(eventId: eventId)
            }
        }
        .onChange(of: viewModel.error) { _, newValue in showError = newValue != nil }
        .alert("common.error".localized, isPresented: $showError) {
            Button("common.ok".localized) {
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

    // MARK: - Total Banner Card
    private var totalBannerCard: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.themeColor)
                Text("EVENT TOTAL")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                Spacer()
            }

            Text("\(viewModel.eventTotal)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.themeColor)

            Text("Total Attendees")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Session Card
    private func sessionCard(_ summary: SessionAttendanceSummaryItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Session header
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(summary.sessionName)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(summary.sessionDate, style: .date)
                        Text("•")
                        Image(systemName: "clock")
                            .font(.caption)
                        Text("\(summary.sessionStartTime, style: .time) - \(summary.sessionEndTime, style: .time)")
                    }
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                // Total count badge
                VStack(spacing: 2) {
                    Text("\(summary.totalCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.themeColor)
                    Text("Total")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
            }

            // Section breakdown (if multiple sections)
            if !summary.sectionCounts.isEmpty {
                Divider()
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                    Text("SECTION BREAKDOWN")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

                    ForEach(summary.sectionCounts) { count in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(count.section ?? "General")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundStyle(.primary)
                                if let notes = count.notes {
                                    Text(notes)
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                                }
                            }

                            Spacer()

                            Text("\(count.count)")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        }
                        .padding(AppTheme.Spacing.s)
                        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    }
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AttendanceSummaryView()
    }
}
