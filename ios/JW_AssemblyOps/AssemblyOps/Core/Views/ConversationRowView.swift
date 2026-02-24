//
//  ConversationRowView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

// MARK: - Conversation Row View
//
// Card component for displaying a conversation thread preview.
//
// Features:
//   - Avatar circle with initials
//   - Other participant name
//   - Subject line and body preview
//   - Unread badge
//   - Timestamp
//
// Used by: ConversationListView

import SwiftUI

struct ConversationRowView: View {
    @Environment(\.colorScheme) var colorScheme

    let conversation: Conversation

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppTheme.themeColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Text(initials)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.themeColor)
            }

            // Content
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack {
                    Text(conversation.otherParticipantName)
                        .font(conversation.unreadCount > 0 ? AppTheme.Typography.headline : AppTheme.Typography.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    if let date = conversation.lastMessageDate {
                        Text(formattedDate(date))
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                }

                if let subject = conversation.subject, !subject.isEmpty {
                    Text(subject)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .lineLimit(1)
                }

                if let body = conversation.lastMessageBody {
                    Text(body)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .lineLimit(2)
                }
            }

            // Unread badge
            if conversation.unreadCount > 0 {
                Text("\(conversation.unreadCount)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(AppTheme.StatusColors.info)
                    .clipShape(Capsule())
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private var initials: String {
        let parts = conversation.otherParticipantName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
            formatter.dateStyle = .none
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        }
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: AppTheme.Spacing.m) {
        ConversationRowView(conversation: .preview)
        ConversationRowView(conversation: .previewRead)
    }
    .screenPadding()
    .themedBackground(scheme: .light)
}
