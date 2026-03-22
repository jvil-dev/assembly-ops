//
//  CaptainAttendanceCountsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/1/26.
//

// MARK: - Captain Attendance Counts View
//
// Displays attendance counts for all posts in the captain's assigned area(s).
// Grouped by post with per-session rows showing count, submitter, and timestamp.

import SwiftUI

struct CaptainAttendanceCountsView: View {
    let eventId: String

    @StateObject private var viewModel = CaptainAttendanceViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    private let deptColor = DepartmentColor.color(for: "ATTENDANT")

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.l) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.counts.isEmpty {
                    emptyView
                } else {
                    ForEach(Array(viewModel.countsByPost.enumerated()), id: \.offset) { index, group in
                        postCard(postName: group.postName, areaName: group.areaName, items: group.items)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.05)
                    }
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("captain.attendance.title".localized)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
        .task {
            await viewModel.load(eventId: eventId)
        }
        .refreshable {
            await viewModel.load(eventId: eventId)
        }
    }

    // MARK: - Post Card

    private func postCard(postName: String, areaName: String?, items: [CaptainAttendanceCountItem]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Header
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(deptColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(postName)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)

                    if let area = areaName {
                        Text(area)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                }

                Spacer()

                Text("\(items.reduce(0) { $0 + $1.count })")
                    .font(AppTheme.Typography.title)
                    .foregroundStyle(deptColor)
            }

            Divider()

            // Session rows
            ForEach(items) { item in
                sessionRow(item)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Session Row

    private func sessionRow(_ item: CaptainAttendanceCountItem) -> some View {
        HStack(spacing: AppTheme.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.sessionName)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.primary)

                Text(item.submittedByName)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(item.count)")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(deptColor)

                Text(DateUtils.timeAgo(from: item.submittedAt))
                    .font(AppTheme.Typography.captionSmall)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }

    // MARK: - Empty

    private var emptyView: some View {
        ContentUnavailableView(
            "captain.attendance.empty".localized,
            systemImage: "chart.bar",
            description: Text("captain.attendance.emptyDesc".localized)
        )
    }

}
