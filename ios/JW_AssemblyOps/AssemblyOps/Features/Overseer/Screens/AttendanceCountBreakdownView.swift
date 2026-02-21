//
//  AttendanceCountBreakdownView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/20/26.
//

// MARK: - Attendance Count Breakdown View
//
// Shows per-section attendance count breakdown for each session.
// Session picker at top, then per-section cards below.
//

import SwiftUI

struct AttendanceCountBreakdownView: View {
    @ObservedObject private var sessionState = OverseerSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var isLoading = false
    @State private var summaries: [SessionAttendanceSummaryItem] = []
    @State private var selectedSessionId: String?
    @State private var error: String?

    private var selectedSummary: SessionAttendanceSummaryItem? {
        summaries.first(where: { $0.sessionId == selectedSessionId })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                if isLoading && summaries.isEmpty {
                    LoadingView(message: "attendant.attendance.title".localized)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                } else if summaries.isEmpty {
                    emptyState
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                } else {
                    sessionPicker
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    if let summary = selectedSummary {
                        totalCard(summary)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                        if summary.sectionCounts.isEmpty {
                            noCountsState
                                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                        } else {
                            ForEach(Array(summary.sectionCounts.enumerated()), id: \.element.id) { index, count in
                                sectionCountCard(count)
                                    .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.03 + 0.1)
                            }
                        }
                    }
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("attendant.attendance.title".localized)
        .refreshable { await loadData() }
        .task { await loadData() }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Session Picker

    private var sessionPicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "calendar")
                    .foregroundStyle(AppTheme.themeColor)
                Text("attendant.attendance.session".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.s) {
                    ForEach(summaries) { summary in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedSessionId = summary.sessionId
                            }
                            HapticManager.shared.lightTap()
                        } label: {
                            Text(summary.sessionName)
                                .font(AppTheme.Typography.subheadline)
                                .padding(.horizontal, AppTheme.Spacing.m)
                                .padding(.vertical, AppTheme.Spacing.s)
                                .background(
                                    selectedSessionId == summary.sessionId
                                        ? AppTheme.themeColor
                                        : AppTheme.cardBackgroundSecondary(for: colorScheme)
                                )
                                .foregroundStyle(selectedSessionId == summary.sessionId ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Total Card

    private func totalCard(_ summary: SessionAttendanceSummaryItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "number")
                    .foregroundStyle(AppTheme.themeColor)
                Text("attendant.attendance.total".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            HStack {
                Text("\(summary.totalCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(summary.sectionCounts.count) \("attendant.attendance.sections".localized)")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Section Count Card

    private func sectionCountCard(_ count: AttendanceCountItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            HStack {
                Text(count.section ?? "attendant.attendance.general".localized)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(count.count)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.themeColor)
            }

            HStack(spacing: AppTheme.Spacing.l) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text(count.submittedByName)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text(count.updatedAt, style: .relative)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
            }

            if let notes = count.notes, !notes.isEmpty {
                Text(notes)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .lineLimit(2)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Image(systemName: "number.square")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Text("attendant.attendance.empty".localized)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxl)
    }

    private var noCountsState: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Text("attendant.attendance.noCounts".localized)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xl)
    }

    // MARK: - Data Loading

    private func loadData() async {
        guard let eventId = sessionState.selectedEvent?.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            summaries = try await AttendanceService.shared.fetchEventAttendanceSummary(eventId: eventId)
            if selectedSessionId == nil, let first = summaries.first {
                selectedSessionId = first.sessionId
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
