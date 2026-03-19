//
//  ConversationListView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

// MARK: - Conversation List View
//
// Shared view displaying conversation threads for both volunteers and overseers.
//
// Features:
//   - Announcements section (both roles) with inline empty state
//   - Messages section with inline empty state
//   - Swipe to delete conversations
//   - Navigation to conversation detail
//   - Pull to refresh
//   - Loading and empty states
//
// Used by: MessagesView (all roles)

import SwiftUI

struct ConversationListView: View {
    @ObservedObject var viewModel: ConversationListViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    let currentUserId: String?
    let isOverseer: Bool

    var body: some View {
        Group {
            if viewModel.isLoading && !viewModel.hasLoaded {
                LoadingView(message: "messages.conversations.loading".localized)
            } else {
                conversationsList
            }
        }
        .task {
            if !viewModel.hasLoaded {
                await viewModel.fetchConversations()
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
            if viewModel.hasLoaded {
                Task { await viewModel.refresh() }
            }
        }
    }

    // MARK: - Conversations List

    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.m) {
                announcementsSection

                messagesHeader

                if isOverseer {
                    ForEach(Array(viewModel.directConversations.enumerated()), id: \.element.id) { index, conversation in
                        conversationRow(conversation, index: index)
                    }
                } else {
                    directConversationRows
                }

                if viewModel.directConversations.isEmpty {
                    inlineEmptyMessages
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.s)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Announcements Section

    private var announcementsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "megaphone")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                Text("messages.announcements.title".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    .textCase(.uppercase)
                    .tracking(0.8)
            }
            .padding(.leading, 4)

            if isOverseer {
                ForEach(Array(viewModel.broadcastConversations.enumerated()), id: \.element.id) { index, conversation in
                    conversationRow(conversation, index: index)
                }
            } else {
                ForEach(viewModel.broadcastConversations) { conversation in
                    NavigationLink {
                        ConversationDetailView(
                            conversationId: conversation.id,
                            otherParticipantName: conversation.displayName,
                            currentUserId: currentUserId,
                            isBroadcast: true
                        )
                    } label: {
                        BroadcastConversationCard(conversation: conversation, colorScheme: colorScheme)
                    }
                    .buttonStyle(.plain)
                }
            }

            if viewModel.broadcastConversations.isEmpty {
                inlineEmptyAnnouncements
            }
        }
    }

    // MARK: - Messages Header

    private var messagesHeader: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Text("messages.section.messages".localized)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                .textCase(.uppercase)
                .tracking(0.8)
        }
        .padding(.leading, 4)
        .padding(.top, AppTheme.Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Direct Conversations (Volunteers)

    private var directConversationRows: some View {
        ForEach(Array(viewModel.directConversations.enumerated()), id: \.element.id) { index, conversation in
            conversationRow(conversation, index: index)
        }
    }

    // MARK: - Single Conversation Row

    private func conversationRow(_ conversation: Conversation, index: Int) -> some View {
        NavigationLink {
            ConversationDetailView(
                conversationId: conversation.id,
                otherParticipantName: conversation.isBroadcast ? conversation.displayName : conversation.otherParticipantName,
                otherParticipantPhone: conversation.otherParticipantPhone,
                otherParticipantCongregation: conversation.otherParticipantCongregation,
                currentUserId: currentUserId,
                isBroadcast: conversation.isBroadcast
            )
        } label: {
            ConversationRowView(conversation: conversation)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                Task {
                    await viewModel.deleteConversation(conversation)
                }
            } label: {
                Label("messages.delete".localized, systemImage: "trash")
            }
        }
        .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.02)
    }

    // MARK: - Inline Empty States

    private var inlineEmptyAnnouncements: some View {
        Text("messages.announcements.empty".localized)
            .font(AppTheme.Typography.subheadline)
            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.xl)
    }

    private var inlineEmptyMessages: some View {
        Text("messages.conversations.empty.inline".localized)
            .font(AppTheme.Typography.subheadline)
            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.xl)
    }
}

// MARK: - Broadcast Conversation Card

private struct BroadcastConversationCard: View {
    let conversation: Conversation
    let colorScheme: ColorScheme

    private var badgeColor: Color {
        conversation.type == .departmentBroadcast ? .blue : .purple
    }

    private var badgeIcon: String {
        conversation.type == .departmentBroadcast ? "person.3" : "megaphone"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack {
                // Type badge
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: badgeIcon)
                        .font(.caption)
                    Text(conversation.type == .departmentBroadcast
                         ? NSLocalizedString("messages.broadcast.department", comment: "")
                         : NSLocalizedString("messages.broadcast.event", comment: ""))
                        .font(AppTheme.Typography.caption)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, AppTheme.Spacing.s)
                .padding(.vertical, 4)
                .background(badgeColor)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

                Spacer()

                // Unread count
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(badgeColor)
                        .clipShape(Capsule())
                }

                if let date = conversation.lastMessageDate {
                    Text(DateUtils.formattedMessageDate(date))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
            }

            // Sender name
            if let senderName = conversation.lastMessageSenderName {
                HStack(spacing: 6) {
                    Image(systemName: "person.circle.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Text(senderName)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
            }

            // Body preview
            if let body = conversation.lastMessageBody {
                Text(body)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .lineLimit(2)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ConversationListView(
        viewModel: ConversationListViewModel(eventId: "event-1", currentUserId: "user-1"),
        currentUserId: "user-1",
        isOverseer: false
    )
}
