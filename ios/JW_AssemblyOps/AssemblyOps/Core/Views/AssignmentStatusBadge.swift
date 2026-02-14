//
//  AssignmentStatusBadge.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/26/26.
//

// MARK: - Assignment Status Badge
//
// A refined capsule-shaped badge displaying assignment status.
// Uses the app's design system for consistent styling.
//
// Features:
//   - Capsule shape for modern appearance
//   - Star icon for captain assignments
//   - Status-specific colors from AppTheme
//   - Compact sizing that works in cards and detail views
//

import SwiftUI

struct AssignmentStatusBadge: View {
    let status: AssignmentStatus
    let isCaptain: Bool

    var body: some View {
        HStack(spacing: 4) {
            if isCaptain {
                Image(systemName: "star.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.yellow)
            }

            Text(status.displayName)
                .font(AppTheme.Typography.captionBold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
        .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch status {
        case .pending:
            return AppTheme.StatusColors.pendingBackground
        case .accepted:
            return AppTheme.StatusColors.acceptedBackground
        case .declined, .autoDeclined:
            return AppTheme.StatusColors.declinedBackground
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .pending:
            return AppTheme.StatusColors.pending
        case .accepted:
            return AppTheme.StatusColors.accepted
        case .declined, .autoDeclined:
            return AppTheme.StatusColors.declined
        }
    }
}

// MARK: - Compact Variant

/// A smaller version of the status badge for tight spaces
struct AssignmentStatusBadgeCompact: View {
    let status: AssignmentStatus

    var body: some View {
        Text(status.displayName)
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch status {
        case .pending:
            return AppTheme.StatusColors.pendingBackground
        case .accepted:
            return AppTheme.StatusColors.acceptedBackground
        case .declined, .autoDeclined:
            return AppTheme.StatusColors.declinedBackground
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .pending:
            return AppTheme.StatusColors.pending
        case .accepted:
            return AppTheme.StatusColors.accepted
        case .declined, .autoDeclined:
            return AppTheme.StatusColors.declined
        }
    }
}

#Preview("Status Badges") {
    VStack(spacing: 16) {
        Text("Standard Badges")
            .font(.headline)

        HStack(spacing: 12) {
            AssignmentStatusBadge(status: .pending, isCaptain: false)
            AssignmentStatusBadge(status: .accepted, isCaptain: false)
            AssignmentStatusBadge(status: .declined, isCaptain: false)
        }

        Text("With Captain Star")
            .font(.headline)
            .padding(.top)

        HStack(spacing: 12) {
            AssignmentStatusBadge(status: .pending, isCaptain: true)
            AssignmentStatusBadge(status: .accepted, isCaptain: true)
        }

        Text("Compact Variant")
            .font(.headline)
            .padding(.top)

        HStack(spacing: 12) {
            AssignmentStatusBadgeCompact(status: .pending)
            AssignmentStatusBadgeCompact(status: .accepted)
            AssignmentStatusBadgeCompact(status: .declined)
        }
    }
    .padding()
}

#Preview("In Context - Light") {
    VStack(spacing: 16) {
        // Simulate card header
        HStack {
            Text("Main Entrance A")
                .font(AppTheme.Typography.headline)
            Spacer()
            AssignmentStatusBadge(status: .pending, isCaptain: false)
        }
        .padding()
        .themedCard(scheme: .light)

        HStack {
            Text("Parking Lot B")
                .font(AppTheme.Typography.headline)
            Spacer()
            AssignmentStatusBadge(status: .accepted, isCaptain: true)
        }
        .padding()
        .themedCard(scheme: .light)
    }
    .padding()
    .themedBackground(scheme: .light)
}
