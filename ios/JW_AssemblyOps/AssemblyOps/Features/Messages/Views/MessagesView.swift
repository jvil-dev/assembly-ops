//
//  MessagesView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/13/26.
//

// MARK: - Messages View
//
// Unified messaging view for all roles (volunteers and overseers).
//
// Features:
//   - Conversations list (all roles)
//   - Compose button to start new 1:1 conversation
//   - Announcement button (overseer only, department/broadcast)
//   - Search button for full-text search
//
// Dependencies:
//   - ConversationListViewModel: Conversations state
//   - MessagesViewModel: Recipients + unread count for badge
//
// Used by: EventTabView (Messages tab, all roles)

import SwiftUI

struct MessagesView: View {
    let isOverseer: Bool

    @StateObject private var inboxViewModel = MessagesViewModel()
    @ObservedObject private var sessionState: EventSessionState = .shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showCompose = false
    @State private var showAnnouncement = false
    @State private var showSearch = false
    @State private var refreshTrigger = UUID()
    @ObservedObject private var pushManager = PushNotificationManager.shared
    @State private var pendingConversation: Conversation?

    private var eventId: String? {
        isOverseer ? sessionState.selectedEvent?.id : AppState.shared.currentEventId
    }

    private var currentUserId: String? {
        AppState.shared.currentUser?.id
    }

    private var accentColor: Color {
        if let deptType = sessionState.selectedDepartment?.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    var body: some View {
        VStack(spacing: 0) {
            // Action bar
            actionBar

            // Conversations wrapped in NavigationStack for push navigation
            NavigationStack {
                conversationsContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationDestination(item: $pendingConversation) { conversation in
                        ConversationDetailView(
                            conversationId: conversation.id,
                            otherParticipantName: conversation.otherParticipantName,
                            otherParticipantPhone: conversation.otherParticipantPhone,
                            otherParticipantCongregation: conversation.otherParticipantCongregation,
                            currentUserId: currentUserId
                        )
                    }
            }
            .scrollContentBackground(.hidden)
        }
        .themedBackground(scheme: colorScheme)
        .task {
            // Fetch recipients for compose
            if inboxViewModel.recipients.isEmpty, let eventId {
                await inboxViewModel.fetchRecipients(eventId: eventId)
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
            // Consume deep link for conversation navigation
            if let deepLink = pushManager.pendingDeepLink, deepLink.isMessageType {
                if let conversationId = deepLink.conversationId {
                    pendingConversation = Conversation(
                        id: conversationId,
                        subject: nil,
                        type: .direct,
                        departmentName: nil,
                        lastMessageBody: nil,
                        lastMessageSenderName: nil,
                        lastMessageDate: nil,
                        otherParticipantName: "...",
                        otherParticipantId: "",
                        otherParticipantPhone: nil,
                        otherParticipantCongregation: nil,
                        unreadCount: 0,
                        updatedAt: Date()
                    )
                }
                pushManager.pendingDeepLink = nil
            }
        }
        .sheet(isPresented: $showCompose, onDismiss: {
            refreshTrigger = UUID()
        }) {
            ComposeMessageView(
                eventId: eventId ?? "",
                currentUserId: currentUserId,
                recipients: inboxViewModel.recipients
            )
        }
        .sheet(isPresented: $showAnnouncement) {
            MessageComposeView()
        }
        .sheet(isPresented: $showSearch) {
            MessageSearchView(eventId: eventId ?? "")
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            Spacer()

            Button {
                showSearch = true
                HapticManager.shared.lightTap()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
            }
            .accessibilityLabel(NSLocalizedString("messages.a11y.search", comment: ""))

            Button {
                showCompose = true
                HapticManager.shared.lightTap()
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(accentColor)
            }
            .accessibilityLabel(NSLocalizedString("messages.a11y.compose", comment: ""))

            if isOverseer {
                Button {
                    showAnnouncement = true
                    HapticManager.shared.lightTap()
                } label: {
                    Image(systemName: "megaphone")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(accentColor)
                }
                .accessibilityLabel(NSLocalizedString("messages.a11y.announce", comment: ""))
            }
        }
        .padding(.horizontal, AppTheme.Spacing.screenEdge)
        .padding(.top, AppTheme.Spacing.s)
        .padding(.bottom, AppTheme.Spacing.xs)
    }

    // MARK: - Conversations Content

    @ViewBuilder
    private var conversationsContent: some View {
        if let eventId, let userId = currentUserId {
            ConversationListWrapper(eventId: eventId, currentUserId: userId, isOverseer: isOverseer, refreshTrigger: refreshTrigger)
        } else {
            VStack(spacing: AppTheme.Spacing.l) {
                Spacer()
                Text("messages.conversations.unavailable".localized)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                Spacer()
            }
        }
    }
}

// MARK: - Conversation List Wrapper

/// Owns the @StateObject for ConversationListViewModel so it survives re-renders.
private struct ConversationListWrapper: View {
    @StateObject private var viewModel: ConversationListViewModel

    let currentUserId: String
    let isOverseer: Bool
    let refreshTrigger: UUID

    init(eventId: String, currentUserId: String, isOverseer: Bool, refreshTrigger: UUID) {
        self.currentUserId = currentUserId
        self.isOverseer = isOverseer
        self.refreshTrigger = refreshTrigger
        _viewModel = StateObject(wrappedValue: ConversationListViewModel(
            eventId: eventId,
            currentUserId: currentUserId
        ))
    }

    var body: some View {
        ConversationListView(viewModel: viewModel, currentUserId: currentUserId, isOverseer: isOverseer)
            .onAppear { viewModel.startListening() }
            .onDisappear { viewModel.stopListening() }
            .onChange(of: refreshTrigger) { _, _ in
                Task { await viewModel.refresh() }
            }
    }
}

#Preview {
    MessagesView(isOverseer: false)
}
