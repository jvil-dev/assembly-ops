//
//  OverseerMessagesView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/9/26.
//

// MARK: - Overseer Messages View
//
// Main messaging hub for overseers with tabs for inbox, conversations, and sent.
// Provides unified interface for bi-directional communication.
//
// Tabs:
//   - Inbox: Received messages (shared with volunteers via inbox content)
//   - Conversations: Active conversation threads
//   - Sent: View sent messages history
//
// Features:
//   - Segmented control for tab navigation
//   - Compose button for new messages
//   - Search button for message search
//   - Unread filter for inbox
//
// Navigation:
//   - Accessed from OverseerTabView
//   - Child tabs handle their own data loading and refresh

import SwiftUI

struct OverseerMessagesView: View {
    @StateObject private var inboxViewModel = MessagesViewModel()
    @StateObject private var sentViewModel = SentMessagesViewModel()
    @ObservedObject private var sessionState: OverseerSessionState = .shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var selectedTab: OverseerMessageTab = .inbox
    @State private var showComposeSheet = false
    @State private var showSearch = false

    private var eventId: String? {
        sessionState.selectedEvent?.id
    }

    private var currentUserId: String? {
        AppState.shared.currentUser?.id
    }

    enum OverseerMessageTab: String, CaseIterable {
        case inbox = "Inbox"
        case conversations = "Conversations"
        case sent = "Sent"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented control
                Picker("", selection: $selectedTab) {
                    ForEach(OverseerMessageTab.allCases, id: \.self) { tab in
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
            .navigationBarTitleDisplayMode(.large)
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

                    if selectedTab == .inbox && inboxViewModel.unreadCount > 0 {
                        markAllReadButton
                    }

                    Button {
                        showComposeSheet = true
                        HapticManager.shared.lightTap()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .task {
                if !inboxViewModel.hasLoaded {
                    await inboxViewModel.fetchMessages()
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
            .sheet(isPresented: $showComposeSheet) {
                MessageComposeView()
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
        case .sent:
            sentContent
        }
    }

    // MARK: - Inbox Content

    private var inboxContent: some View {
        Group {
            if !inboxViewModel.hasLoaded {
                LoadingView(message: "messages.loading".localized)
            } else if let error = inboxViewModel.errorMessage, inboxViewModel.isEmpty {
                ErrorView(message: error) {
                    await inboxViewModel.refresh()
                }
            } else if inboxViewModel.isEmpty {
                ScrollView {
                    EmptyMessagesView(showUnreadOnly: inboxViewModel.showUnreadOnly)
                }
                .refreshable {
                    await inboxViewModel.refresh()
                }
            } else {
                inboxList
            }
        }
    }

    // MARK: - Inbox List

    private var inboxList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.m) {
                ForEach(Array(inboxViewModel.filteredMessages.enumerated()), id: \.element.id) { index, message in
                    NavigationLink(value: message) {
                        MessageRowView(message: message)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                await inboxViewModel.deleteMessage(message)
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
            await inboxViewModel.refresh()
        }
        .themedBackground(scheme: colorScheme)
        .navigationDestination(for: Message.self) { message in
            MessageDetailView(message: message) {
                await inboxViewModel.markAsRead(message)
            } onDelete: {
                await inboxViewModel.deleteMessage(message)
            }
        }
    }

    // MARK: - Conversations Content

    @ViewBuilder
    private var conversationsContent: some View {
        if let eventId, let userId = currentUserId {
            OverseerConversationListWrapper(eventId: eventId, currentUserId: userId)
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

    // MARK: - Sent Content

    private var sentContent: some View {
        Group {
            if sentViewModel.isLoading && !sentViewModel.hasLoaded {
                LoadingView(message: "messages.loading".localized)
            } else if sentViewModel.isEmpty {
                sentEmptyState
            } else {
                sentList
            }
        }
        .task {
            if !sentViewModel.hasLoaded {
                await sentViewModel.fetchMessages()
            }
        }
    }

    private var sentEmptyState: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Spacer()

            Image(systemName: "paperplane")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Text("messages.sent.empty.title".localized)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("messages.sent.empty.subtitle".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppTheme.Spacing.screenEdge)
        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
    }

    private var sentList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.m) {
                ForEach(Array(sentViewModel.messages.enumerated()), id: \.element.id) { index, message in
                    SentMessageRow(message: message, colorScheme: colorScheme)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.03)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.s)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .refreshable {
            await sentViewModel.refresh()
        }
    }

    // MARK: - Filter Button

    private var filterButton: some View {
        Button {
            inboxViewModel.showUnreadOnly.toggle()
            HapticManager.shared.lightTap()
        } label: {
            Label(
                inboxViewModel.showUnreadOnly ? "messages.filter.all".localized : "messages.filter.unread".localized,
                systemImage: inboxViewModel.showUnreadOnly ? "envelope" : "envelope.badge"
            )
        }
    }

    // MARK: - Mark All Read

    private var markAllReadButton: some View {
        Button {
            Task {
                await inboxViewModel.markAllAsRead()
            }
        } label: {
            Label("messages.markAllRead".localized, systemImage: "checkmark.circle")
        }
    }
}

// MARK: - Overseer Conversation List Wrapper

private struct OverseerConversationListWrapper: View {
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

// MARK: - Sent Message Row (moved from SentMessagesView for reuse)

struct SentMessageRow: View {
    let message: SentMessageItem
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Header row: recipient type badge + timestamp
            HStack {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: recipientIcon)
                        .font(.caption)
                    Text(message.recipientTypeDisplayName)
                        .font(AppTheme.Typography.caption)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, AppTheme.Spacing.s)
                .padding(.vertical, 4)
                .background(recipientColor)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

                Spacer()

                Text(timeAgo)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Recipient name (if individual)
            if let recipientName = message.recipientName {
                HStack(spacing: 6) {
                    Image(systemName: "person.circle.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Text(recipientName)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
            }

            // Subject (if present)
            if let subject = message.subject, !subject.isEmpty {
                Text(subject)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
            }

            // Body preview (first 2 lines)
            Text(message.body)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .lineLimit(2)

            // Read status indicator (for individual messages)
            if message.recipientType == "VOLUNTEER" {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: message.isRead ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundStyle(message.isRead ? AppTheme.StatusColors.accepted : AppTheme.textTertiary(for: colorScheme))
                    Text(message.isRead ? "Read" : "Unread")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private var recipientIcon: String {
        switch message.recipientType {
        case "VOLUNTEER": return "person"
        case "DEPARTMENT": return "person.3"
        case "EVENT": return "megaphone"
        default: return "envelope"
        }
    }

    private var recipientColor: Color {
        switch message.recipientType {
        case "VOLUNTEER": return AppTheme.themeColor
        case "DEPARTMENT": return .blue
        case "EVENT": return .purple
        default: return .gray
        }
    }

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: message.createdAt, relativeTo: Date())
    }
}

// MARK: - Preview
#Preview {
    OverseerMessagesView()
}
