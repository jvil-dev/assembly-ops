//
//  AttendanceCountReminderBanner.swift
//  AssemblyOps
//
//  Created by Claude on 3/1/26.
//

// MARK: - Attendance Count Reminder Banner
//
// Non-blocking banner shown when a volunteer hasn't submitted their
// attendance count and a session is nearing its end (within 30 min).
// Tappable — navigates to the count submission view.

import SwiftUI

struct AttendanceReminderItem: Identifiable {
    let id: String // sessionId
    let sessionName: String
    let postId: String?
    let postName: String?
    let sessionEndTime: Date
}

struct AttendanceCountReminderBanner: View {
    let reminders: [AttendanceReminderItem]
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if let reminder = reminders.first {
            HStack(spacing: AppTheme.Spacing.m) {
                Image(systemName: "number.square.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.StatusColors.warning)

                VStack(alignment: .leading, spacing: 2) {
                    Text("attendance.reminder.title".localized)
                        .font(AppTheme.Typography.subheadline.bold())
                        .foregroundStyle(AppTheme.StatusColors.warning)

                    if let postName = reminder.postName {
                        Text(String(format: "attendance.reminder.message".localized, postName, reminder.sessionName))
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.primary)
                    } else {
                        Text(String(format: "attendance.reminder.messageNoPost".localized, reminder.sessionName))
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.primary)
                    }
                }

                Spacer()

                Text("attendance.reminder.submit".localized)
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppTheme.Spacing.s)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(AppTheme.StatusColors.warning)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
            }
            .padding(AppTheme.Spacing.m)
            .background(AppTheme.StatusColors.warning.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
    }
}
