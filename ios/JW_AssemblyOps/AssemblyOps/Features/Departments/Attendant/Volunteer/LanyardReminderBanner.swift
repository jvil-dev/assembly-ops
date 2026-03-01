//
//  LanyardReminderBanner.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/1/26.
//

// MARK: - Lanyard Reminder Banner
//
// Non-blocking banner displayed in the attendant volunteer view.
// Shows contextual lanyard reminders:
//   - "Pick up your lanyard" when not picked up
//   - "Return your lanyard" when picked up but not returned
// Tappable — navigates to LanyardStatusView.
//

import SwiftUI

struct LanyardReminderBanner: View {
    let status: LanyardStatusItem?
    var isUrgent: Bool = false
    @Environment(\.colorScheme) var colorScheme

    private var shouldShow: Bool {
        guard let status = status else { return true } // No status = not picked up
        return status.status != .returned
    }

    private var needsPickup: Bool {
        guard let status = status else { return true }
        return status.status == .notPickedUp
    }

    private var bannerText: String {
        guard let status = status else {
            return isUrgent ? "lanyard.urgent.message".localized : "lanyard.banner.pickUp".localized
        }
        switch status.status {
        case .notPickedUp:
            return isUrgent ? "lanyard.urgent.message".localized : "lanyard.banner.pickUp".localized
        case .pickedUp: return "lanyard.banner.return".localized
        case .returned: return ""
        }
    }

    private var bannerIcon: String {
        if isUrgent && needsPickup { return "exclamationmark.triangle.fill" }
        guard let status = status else { return "lanyard" }
        switch status.status {
        case .notPickedUp: return "lanyard"
        case .pickedUp: return "arrow.down.circle"
        case .returned: return "checkmark.circle"
        }
    }

    private var bannerColor: Color {
        if isUrgent && needsPickup { return AppTheme.StatusColors.declined }
        guard let status = status else { return AppTheme.StatusColors.warning }
        switch status.status {
        case .notPickedUp: return AppTheme.StatusColors.warning
        case .pickedUp: return AppTheme.StatusColors.info
        case .returned: return AppTheme.StatusColors.accepted
        }
    }

    var body: some View {
        if shouldShow {
            NavigationLink(destination: LanyardStatusView()) {
                HStack(spacing: AppTheme.Spacing.m) {
                    Image(systemName: bannerIcon)
                        .font(isUrgent && needsPickup ? .title3 : .body)
                        .foregroundStyle(bannerColor)

                    VStack(alignment: .leading, spacing: 2) {
                        if isUrgent && needsPickup {
                            Text("lanyard.urgent.title".localized)
                                .font(AppTheme.Typography.subheadline.bold())
                                .foregroundStyle(bannerColor)
                        }
                        Text(bannerText)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    if isUrgent && needsPickup {
                        Text("lanyard.urgent.goPickup".localized)
                            .font(AppTheme.Typography.captionBold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, AppTheme.Spacing.s)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .background(bannerColor)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(AppTheme.Spacing.m)
                .background(bannerColor.opacity(isUrgent && needsPickup ? 0.15 : 0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                .overlay(
                    isUrgent && needsPickup ?
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .stroke(bannerColor.opacity(0.3), lineWidth: 1)
                    : nil
                )
            }
            .buttonStyle(.plain)
        }
    }
}
