//
//  CheckInStatsCard.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/9/26.
//

// MARK: - Check-In Stats Card
//
// Reusable card component for displaying check-in statistics for a session.
// Shows assigned count, checked-in count, completion percentage, and attendance count.
//
// Parameters:
//   - stats: CheckInStatsItem with session data and check-in metrics
//
// Features:
//   - Color-coded progress bar (green when complete, theme color otherwise)
//   - Displays attendance count if available
//   - Follows AppTheme design system

import SwiftUI

struct CheckInStatsCard: View {
    let stats: CheckInStatsItem
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Section header
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(AppTheme.themeColor)
                Text("stats.checkin".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Session name
            Text(stats.sessionName)
                .font(AppTheme.Typography.headline)

            // Stats row: 4 columns
            HStack(spacing: AppTheme.Spacing.m) {
                statColumn(value: stats.checkedIn, label: "stats.checked.in".localized, color: AppTheme.StatusColors.accepted)
                statColumn(value: stats.checkedOut, label: "stats.checked.out".localized, color: AppTheme.StatusColors.info)
                statColumn(value: stats.noShow, label: "stats.no.show".localized, color: AppTheme.StatusColors.declined)
                statColumn(value: stats.pending, label: "stats.pending".localized, color: AppTheme.StatusColors.pending)
            }

            // Progress bar
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack {
                    Text("stats.rate".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Spacer()
                    Text("\(Int(stats.attendanceRate * 100))%")
                        .font(AppTheme.Typography.captionBold)
                        .foregroundStyle(AppTheme.themeColor)
                }
                ProgressView(value: stats.attendanceRate)
                    .tint(AppTheme.themeColor)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private func statColumn(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
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
}

// MARK: - Preview
#Preview {
    CheckInStatsCard(stats: CheckInStatsItem(
        sessionId: "1",
        sessionName: "Friday Morning",
        totalAssignments: 50,
        checkedIn: 40,
        checkedOut: 5,
        noShow: 3,
        pending: 2
    ))
    .padding()
}
