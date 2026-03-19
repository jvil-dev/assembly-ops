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
            if conversation.isBroadcast {
                ZStack {
                    Circle()
                        .fill(broadcastColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: broadcastIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(broadcastColor)
                }
            } else {
                ZStack {
                    Circle()
                        .fill(AppTheme.themeColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Text(initials)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.themeColor)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack {
                    Text(conversation.displayName)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var broadcastColor: Color {
        conversation.type == .departmentBroadcast ? .blue : .purple
    }

    private var broadcastIcon: String {
        conversation.type == .departmentBroadcast ? "person.3" : "megaphone"
    }

    private var accessibilityDescription: String {
        var parts: [String] = []
        parts.append(conversation.displayName)
        if let subject = conversation.subject, !subject.isEmpty {
            parts.append(subject)
        }
        if let body = conversation.lastMessageBody {
            parts.append(body)
        }
        if conversation.unreadCount > 0 {
            parts.append("\(conversation.unreadCount) unread")
        }
        if let date = conversation.lastMessageDate {
            parts.append(formattedDate(date))
        }
        return parts.joined(separator: ", ")
    }

    private var initials: String {
        let parts = conversation.otherParticipantName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }

    private func formattedDate(_ date: Date) -> String {
        DateUtils.formattedMessageDate(date)
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
