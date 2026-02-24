//
//  MessagesView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/13/26.
//

// MARK: - Messages View
//
// Main view for volunteer messaging with bi-directional support.
//
// Features:
//   - Segmented control: Inbox / Conversations
//   - Compose button to start new conversation
//   - Search button for full-text search
//   - Pull to refresh
//   - Filter toggle (all vs unread only)
//   - Mark all as read
//   - Swipe to delete messages
//   - Navigation to message detail or conversation detail
//
// Dependencies:
//   - MessagesViewModel: Inbox state
//   - ConversationListViewModel: Conversations state
//   - MessageRowView, ConversationRowView: Row components
//
// Used by: VolunteerTabView

import SwiftUI

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var selectedTab: MessageTab = .inbox
    @State private var showCompose = false
    @State private var showSearch = false

    private var eventId: String? {
        AppState.shared.currentVolunteer?.eventId
    }

    private var currentUserId: String? {
        AppState.shared.currentVolunteer?.id
    }

    enum MessageTab: String, CaseIterable {
        case inbox = "Inbox"
        case conversations = "Conversations"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented control
                Picker("", selection: $selectedTab) {
                    ForEach(MessageTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.Spacing.screenEdge)
                .padding(.top, AppTheme.Spacing.s)
                .padding(.bottom, AppTheme.Spacing.s)

                // Tab content
                tabContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("messages.title".localized)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if selectedTab == .inbox {
                        filterButton
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showSearch = true
                        HapticManager.shared.lightTap()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }

                    if selectedTab == .inbox && viewModel.unreadCount > 0 {
                        markAllReadButton
                    }

                    Button {
                        showCompose = true
                        HapticManager.shared.lightTap()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .task {
                if !viewModel.hasLoaded {
                    await viewModel.fetchMessages()
                }
                if viewModel.recipients.isEmpty, let eventId {
                    await viewModel.fetchRecipients(eventId: eventId)
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
            .sheet(isPresented: $showCompose) {
                ComposeMessageView(
                    eventId: eventId ?? "",
                    currentUserId: currentUserId,
                    onSent: { _ in
                        Task {
                            await viewModel.fetchMessages()
                        }
                    },
                    recipients: viewModel.recipients
                )
            }
            .sheet(isPresented: $showSearch) {
                MessageSearchView(eventId: eventId ?? "")
            }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .inbox:
            inboxContent
        case .conversations:
            conversationsContent
        }
    }

    // MARK: - Inbox Content

    private var inboxContent: some View {
        Group {
            if !viewModel.hasLoaded {
                LoadingView(message: "messages.loading".localized)
            } else if let error = viewModel.errorMessage, viewModel.isEmpty {
                ErrorView(message: error) {
                    await viewModel.refresh()
                }
            } else if viewModel.isEmpty {
                ScrollView {
                    EmptyMessagesView(showUnreadOnly: viewModel.showUnreadOnly)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            } else {
                messagesList
            }
        }
    }

    // MARK: - Conversations Content

    @ViewBuilder
    private var conversationsContent: some View {
        if let eventId, let userId = currentUserId {
            ConversationListWrapper(eventId: eventId, currentUserId: userId)
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

    // MARK: - Filter Button

    private var filterButton: some View {
        Button {
            viewModel.showUnreadOnly.toggle()
            HapticManager.shared.lightTap()
        } label: {
            Label(
                viewModel.showUnreadOnly ? "messages.filter.all".localized : "messages.filter.unread".localized,
                systemImage: viewModel.showUnreadOnly ? "envelope" : "envelope.badge"
            )
        }
    }

    // MARK: - Mark All Read

    private var markAllReadButton: some View {
        Button {
            Task {
                await viewModel.markAllAsRead()
            }
        } label: {
            Label("messages.markAllRead".localized, systemImage: "checkmark.circle")
        }
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.m) {
                ForEach(Array(viewModel.filteredMessages.enumerated()), id: \.element.id) { index, message in
                    NavigationLink(value: message) {
                        MessageRowView(message: message)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteMessage(message)
                            }
                        } label: {
                            Label("messages.delete".localized, systemImage: "trash")
                        }
                    }
                    .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.02)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .refreshable {
            await viewModel.refresh()
        }
        .themedBackground(scheme: colorScheme)
        .navigationDestination(for: Message.self) { message in
            MessageDetailView(message: message) {
                await viewModel.markAsRead(message)
            } onDelete: {
                await viewModel.deleteMessage(message)
            }
        }
    }
}

// MARK: - Conversation List Wrapper

/// Owns the @StateObject for ConversationListViewModel so it survives re-renders
/// when the parent MessagesView switches between tabs.
private struct ConversationListWrapper: View {
    @StateObject private var viewModel: ConversationListViewModel

    let currentUserId: String

    init(eventId: String, currentUserId: String) {
        self.currentUserId = currentUserId
        _viewModel = StateObject(wrappedValue: ConversationListViewModel(
            eventId: eventId,
            currentUserId: currentUserId
        ))
    }

    var body: some View {
        ConversationListView(viewModel: viewModel, currentUserId: currentUserId)
    }
}

// MARK: - Hashable Conformance for Navigation
extension Message: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}

#Preview {
    MessagesView()
}
