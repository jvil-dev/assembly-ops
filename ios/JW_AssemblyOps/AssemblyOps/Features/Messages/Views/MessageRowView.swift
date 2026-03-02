//
//  MessageRowView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/13/26.
//

// MARK: - Message Row View
//
// Card component for displaying a single message preview.
//
// Features:
//   - Unread dot indicator
//   - Icon based on recipient type (person/group/megaphone)
//   - Subject with bold styling for unread
//   - Sender name and timestamp
//   - Body preview (2 lines)
//
// Used by: MessagesView

import SwiftUI

struct MessageRowView: View {
    @Environment(\.colorScheme) var colorScheme

    let message: Message

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Recipient type icon with colored circle
            ZStack {
                Circle()
                    .fill(recipientColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: message.recipientType.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(recipientColor)
            }

            // Content
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack {
                    Text(message.displaySubject)
                        .font(message.isRead ? AppTheme.Typography.subheadline : AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    Text(message.formattedDate)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                if let sender = message.senderName {
                    Text(sender)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                Text(message.body)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .lineLimit(2)
            }

            // Unread indicator
            if !message.isRead {
                Circle()
                    .fill(AppTheme.StatusColors.info)
                    .frame(width: 10, height: 10)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private var recipientColor: Color {
        switch message.recipientType {
        case .volunteer: return AppTheme.themeColor
        case .department: return .blue
        case .event: return .purple
        case .admin: return .orange
        }
    }
}

#Preview {
    VStack(spacing: AppTheme.Spacing.m) {
        MessageRowView(message: .preview)
        MessageRowView(message: .previewRead)
        MessageRowView(message: .previewDepartment)
    }
    .screenPadding()
    .themedBackground(scheme: .light)
}
