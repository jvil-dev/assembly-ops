//
//  AssignmentCardView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Assignment Card View
//
// A floating card component displaying assignment summary information.
// Uses the app's design system for consistent styling with warm backgrounds.
//
// Features:
//   - Department color accent stripe on left edge
//   - Status badge with captain indicator
//   - Location and time details
//   - Deadline warning for pending assignments
//   - Check-in status indicator
//   - Entrance animation support
//

import SwiftUI

struct AssignmentCardView: View {
    @Environment(\.colorScheme) var colorScheme

    let assignment: Assignment
    var hasSessionConflict: Bool = false

    var body: some View {
        cardContent
    }

    private var cardContent: some View {
        HStack(spacing: 0) {
            // Department color accent stripe
            accentStripe

            // Main content
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                // Header: Post name + Status badge
                headerRow

                // Department with color dot
                departmentRow

                // Category (if available)
                if let category = assignment.postCategory {
                    detailRow(icon: "tag.fill", text: category)
                }

                // Location (if available)
                if let location = assignment.postLocation {
                    detailRow(icon: "mappin.circle.fill", text: location)
                }

                // Time: show when a shift or dept-configured session time is set
                if !assignment.timeRangeFormatted.isEmpty {
                    detailRow(icon: "clock.fill", text: assignment.timeRangeFormatted)
                    if let shiftName = assignment.shiftName {
                        detailRow(icon: "clock.arrow.2.circlepath", text: shiftName)
                    }
                }

                // Deadline warning for pending
                if let deadlineText = assignment.deadlineText {
                    deadlineRow(text: deadlineText)
                }

                // Multi-assignment session warning
                if hasSessionConflict {
                    sessionConflictRow
                }

                // Check-in status for accepted
                if assignment.isAccepted {
                    checkInStatusRow
                }
            }
            .padding(AppTheme.Spacing.cardPadding)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        .shadow(
            color: AppTheme.Shadow.cardPrimary.color,
            radius: AppTheme.Shadow.cardPrimary.radius,
            x: AppTheme.Shadow.cardPrimary.x,
            y: AppTheme.Shadow.cardPrimary.y
        )
        .shadow(
            color: AppTheme.Shadow.cardSecondary.color,
            radius: AppTheme.Shadow.cardSecondary.radius,
            x: AppTheme.Shadow.cardSecondary.x,
            y: AppTheme.Shadow.cardSecondary.y
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var parts: [String] = []
        parts.append(assignment.postName)
        parts.append(assignment.departmentName)
        parts.append("Status: \(assignment.status.displayName)")
        if assignment.isCaptain {
            parts.append("Captain")
        }
        if let location = assignment.postLocation {
            parts.append(location)
        }
        if !assignment.timeRangeFormatted.isEmpty {
            parts.append(assignment.timeRangeFormatted)
        }
        if assignment.isCheckedIn {
            parts.append("Checked in")
        } else if assignment.canCheckIn {
            parts.append("Ready to check in")
        }
        if let deadlineText = assignment.deadlineText {
            parts.append(deadlineText)
        }
        return parts.joined(separator: ", ")
    }

    // MARK: - Accent Stripe

    private var accentStripe: some View {
        Rectangle()
            .fill(assignment.departmentColor)
            .frame(width: 4)
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(alignment: .center) {
            Text(assignment.postName)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Spacer()

            AssignmentStatusBadge(
                status: assignment.status,
                isCaptain: assignment.isCaptain,
                departmentType: assignment.departmentType
            )
        }
    }

    // MARK: - Department Row

    private var departmentRow: some View {
        HStack(spacing: AppTheme.Spacing.s) {
            Circle()
                .fill(assignment.departmentColor)
                .frame(width: 8, height: 8)

            Text(assignment.departmentName)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
    }

    // MARK: - Detail Row

    private func detailRow(icon: String, text: String) -> some View {
        HStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                .frame(width: 16)

            Text(text)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
    }

    // MARK: - Deadline Row

    private func deadlineRow(text: String) -> some View {
        HStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.StatusColors.warning)

            Text(text)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.StatusColors.warning)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppTheme.StatusColors.warningBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Session Conflict Row

    private var sessionConflictRow: some View {
        HStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.StatusColors.warning)

            Text(NSLocalizedString("assignment.sessionConflict", comment: ""))
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.StatusColors.warning)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppTheme.StatusColors.warningBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Check-in Status Row

    @ViewBuilder
    private var checkInStatusRow: some View {
        if assignment.isCheckedIn {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.StatusColors.accepted)

                Text(NSLocalizedString("assignment.checkedIn", comment: ""))
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.StatusColors.accepted)
            }
        } else if assignment.canCheckIn {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "circle")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.StatusColors.info)

                Text(NSLocalizedString("assignment.readyToCheckIn", comment: ""))
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.StatusColors.info)
            }
        }
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        let base: Color = {
            if assignment.isPending {
                return colorScheme == .dark
                    ? AppTheme.cardBackground(for: colorScheme)
                    : Color.white.opacity(0.95)
            } else if assignment.isToday && assignment.isAccepted {
                return colorScheme == .dark
                    ? AppTheme.cardBackground(for: colorScheme)
                    : Color.white
            }
            return AppTheme.cardBackground(for: colorScheme)
        }()

        return ZStack {
            base
            assignment.departmentColor.opacity(colorScheme == .dark ? 0.08 : 0.06)
        }
    }
}

// MARK: - Preview

#Preview("Assignment Cards") {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.m) {
            AssignmentCardView(assignment: .preview)
            AssignmentCardView(assignment: .previewPending)
            AssignmentCardView(assignment: .previewCaptain)
            AssignmentCardView(assignment: .previewCheckedIn)
        }
        .screenPadding()
        .padding(.vertical)
    }
    .themedBackground(scheme: .light)
}

#Preview("Dark Mode") {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.m) {
            AssignmentCardView(assignment: .preview)
            AssignmentCardView(assignment: .previewPending)
            AssignmentCardView(assignment: .previewCaptain)
        }
        .screenPadding()
        .padding(.vertical)
    }
    .themedBackground(scheme: .dark)
    .preferredColorScheme(.dark)
}
