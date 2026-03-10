//
//  CaptainAssignmentCardView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/1/26.
//

// MARK: - Captain Assignment Card View
//
// A card component for captain area assignments.
// Mirrors AssignmentCardView styling but shows area info
// instead of post info, with a "Captain" role badge.
//

import SwiftUI

struct CaptainAssignmentCardView: View {
    @Environment(\.colorScheme) var colorScheme

    let assignment: CaptainAssignment

    var body: some View {
        cardContent
    }

    private var cardContent: some View {
        HStack(spacing: 0) {
            accentStripe

            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                headerRow
                departmentRow

                if let description = assignment.areaDescription {
                    detailRow(icon: "mappin.circle.fill", text: description)
                }

                if !assignment.timeRangeFormatted.isEmpty {
                    detailRow(icon: "clock.fill", text: assignment.timeRangeFormatted)
                }

                if let deadlineText = assignment.deadlineText {
                    deadlineRow(text: deadlineText)
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
    }

    // MARK: - Accent Stripe

    private var accentStripe: some View {
        Rectangle()
            .fill(DepartmentColor.color(for: assignment.departmentType))
            .frame(width: 4)
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("captain.role".localized)
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(AppTheme.StatusColors.warning)

                Text(assignment.areaName)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
            }

            Spacer()

            AssignmentStatusBadge(
                status: assignment.status,
                isCaptain: true,
                departmentType: assignment.departmentType
            )
        }
    }

    // MARK: - Department Row

    private var departmentRow: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(DepartmentColor.color(for: assignment.departmentType))
                .frame(width: 8, height: 8)

            Text(assignment.departmentName)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
    }

    // MARK: - Detail Row

    private func detailRow(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
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
        HStack(spacing: 6) {
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

    // MARK: - Card Background

    private var cardBackground: some View {
        let base: Color = {
            if assignment.isPending {
                return colorScheme == .dark
                    ? AppTheme.cardBackground(for: colorScheme)
                    : Color.white.opacity(0.95)
            }
            return AppTheme.cardBackground(for: colorScheme)
        }()

        return ZStack {
            base
            DepartmentColor.color(for: assignment.departmentType).opacity(colorScheme == .dark ? 0.08 : 0.06)
        }
    }
}

// MARK: - Preview

#Preview("Captain Assignment Cards") {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.m) {
            CaptainAssignmentCardView(assignment: .preview)
            CaptainAssignmentCardView(assignment: .previewAccepted)
            CaptainAssignmentCardView(assignment: .previewForceAssigned)
        }
        .screenPadding()
        .padding(.vertical)
    }
    .themedBackground(scheme: .light)
}
