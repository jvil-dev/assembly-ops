//
//  AreaCaptainGroupContent.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

// MARK: - Area Captain Group Content
//
// Presentational view for area-scoped captain groups (Attendant department).
// Renders area name, I/E/S category badge, members grouped by post,
// and check-in controls.
//
// Parameters:
//   - group: The area group data (nil shows empty state)
//   - isLoading: Whether group data is still loading
//   - onCheckIn: Callback after captain checks in a member

import SwiftUI

struct AreaCaptainGroupContent: View {
    let group: AreaGroupItem?
    let isLoading: Bool
    let onCheckIn: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else if let group = group {
            groupContent(group)
        } else {
            Text("attendant.captain.areaGroup.noGroup".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
    }

    // MARK: - Group Content

    @ViewBuilder
    private func groupContent(_ group: AreaGroupItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Area name + category badge
            HStack(spacing: AppTheme.Spacing.s) {
                Text(group.areaName)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundStyle(.primary)

                if let category = group.areaCategory {
                    Text(AttendantMainCategory.displayString(for: category))
                        .font(AppTheme.Typography.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.themeColor.opacity(0.12))
                        .foregroundStyle(AppTheme.themeColor)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.badge))
                }
            }

            if let desc = group.areaDescription, !desc.isEmpty {
                Text(desc)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            if group.members.isEmpty {
                Text("attendant.captain.areaGroup.noMembers".localized)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            } else {
                membersGroupedByPost(group.members)
            }
        }
    }

    // MARK: - Members Grouped by Post

    @ViewBuilder
    private func membersGroupedByPost(_ members: [AreaGroupMemberItem]) -> some View {
        let grouped = Dictionary(grouping: members) { $0.postName }
        let sortedKeys = grouped.keys.sorted()

        ForEach(sortedKeys, id: \.self) { postName in
            if let postMembers = grouped[postName] {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    // Post header
                    Text(postName)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        .padding(.top, AppTheme.Spacing.xs)

                    ForEach(postMembers) { member in
                        AreaGroupMemberRow(
                            member: member,
                            onCheckIn: {
                                try? await AssignmentsService.shared.captainCheckIn(
                                    assignmentId: member.assignmentId,
                                    notes: nil
                                )
                                onCheckIn()
                            }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Area Group Member Row

private struct AreaGroupMemberRow: View {
    let member: AreaGroupMemberItem
    let onCheckIn: () async -> Void

    @State private var isCheckingIn = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(member.volunteerName)
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.medium)

                Text(member.congregation)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            Spacer()

            if member.checkInStatus == "CHECKED_IN" {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    if let time = member.checkInTime {
                        Text(time, style: .time)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                }
            } else if member.status == "ACCEPTED" && !member.isCaptain {
                Button(action: {
                    Task {
                        isCheckingIn = true
                        await onCheckIn()
                        isCheckingIn = false
                    }
                }) {
                    if isCheckingIn {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Check In")
                            .font(AppTheme.Typography.captionBold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.themeColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.badge))
                    }
                }
                .disabled(isCheckingIn)
            } else {
                Text(member.status.capitalized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .padding(.vertical, 8)
    }
}
