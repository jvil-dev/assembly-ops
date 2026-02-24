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
//   - List of conversation threads with preview
//   - Swipe to delete conversations
//   - Navigation to conversation detail
//   - Pull to refresh
//   - Loading and empty states
//
// Used by: MessagesView (volunteer), OverseerMessagesView (overseer)

import SwiftUI

struct ConversationListView: View {
    @ObservedObject var viewModel: ConversationListViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    let currentUserId: String?

    var body: some View {
        Group {
            if viewModel.isLoading && !viewModel.hasLoaded {
                LoadingView(message: "messages.conversations.loading".localized)
            } else if viewModel.isEmpty {
                emptyState
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
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Spacer()

            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Text("messages.conversations.empty.title".localized)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("messages.conversations.empty.subtitle".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppTheme.Spacing.screenEdge)
        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
    }

    // MARK: - Conversations List

    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.m) {
                ForEach(Array(viewModel.conversations.enumerated()), id: \.element.id) { index, conversation in
                    NavigationLink {
                        ConversationDetailView(
                            conversationId: conversation.id,
                            otherParticipantName: conversation.otherParticipantName,
                            currentUserId: currentUserId
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
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.s)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}
