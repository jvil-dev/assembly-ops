//
//  ConversationDetailView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

// MARK: - Conversation Detail View
//
// Chat-style thread view with message bubbles.
//
// Features:
//   - Chat bubble layout (sent right, received left)
//   - Sender name and timestamp on each bubble
//   - Reply input field at the bottom
//   - Auto-marks conversation as read
//   - Auto-scrolls to newest message
//
// Used by: ConversationListView (navigation destination)

import SwiftUI

struct ConversationDetailView: View {
    @StateObject private var viewModel: ConversationDetailViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var replyText = ""
    @State private var hasAppeared = false
    @FocusState private var isReplyFocused: Bool

    let otherParticipantName: String

    init(conversationId: String, otherParticipantName: String, currentUserId: String?) {
        self.otherParticipantName = otherParticipantName
        _viewModel = StateObject(wrappedValue: ConversationDetailViewModel(
            conversationId: conversationId,
            currentUserId: currentUserId
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.s) {
                        ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: viewModel.isFromCurrentUser(message),
                                colorScheme: colorScheme
                            )
                            .id(message.id)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.02)
                        }
                    }
                    .screenPadding()
                    .padding(.top, AppTheme.Spacing.m)
                    .padding(.bottom, AppTheme.Spacing.m)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Reply input
            replyBar
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle(otherParticipantName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !viewModel.hasLoaded {
                await viewModel.fetchMessages()
                await viewModel.markAsRead()
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Reply Bar

    private var replyBar: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            TextField("messages.conversation.reply.placeholder".localized, text: $replyText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .focused($isReplyFocused)
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.vertical, AppTheme.Spacing.s)
                .background(AppTheme.cardBackground(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )

            Button {
                let text = replyText
                replyText = ""
                Task {
                    await viewModel.sendReply(body: text)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? AppTheme.themeColor : AppTheme.textTertiary(for: colorScheme))
            }
            .disabled(!canSend || viewModel.isSending)
        }
        .padding(.horizontal, AppTheme.Spacing.screenEdge)
        .padding(.vertical, AppTheme.Spacing.s)
        .background(AppTheme.cardBackground(for: colorScheme))
    }

    private var canSend: Bool {
        !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    let colorScheme: ColorScheme

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 50) }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: AppTheme.Spacing.xs) {
                // Sender name (only for received messages)
                if !isFromCurrentUser, let name = message.senderName {
                    Text(name)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                // Bubble
                Text(message.body)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(isFromCurrentUser ? .white : .primary)
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.vertical, AppTheme.Spacing.s)
                    .background(isFromCurrentUser ? AppTheme.themeColor : AppTheme.cardBackground(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)

                // Timestamp
                Text(message.formattedDate)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            if !isFromCurrentUser { Spacer(minLength: 50) }
        }
    }
}
