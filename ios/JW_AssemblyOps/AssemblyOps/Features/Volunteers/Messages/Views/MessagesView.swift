//
//  MessagesView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/13/26.
//

// MARK: - Messages View
//
// Main view for displaying volunteer messages from overseers.
//
// Features:
//   - Themed card rows with unread indicators
//   - Pull to refresh
//   - Filter toggle (all vs unread only)
//   - Mark all as read button
//   - Navigation to message detail
//   - Loading, error, and empty states
//
// Dependencies:
//   - MessagesViewModel: State management
//   - MessageRowView: Row component
//   - MessageDetailView: Detail view
//   - EmptyMessagesView: Empty state
//   - LoadingView, ErrorView: Shared components
//
// Used by: MainTabView

import SwiftUI

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.hasLoaded {
                    LoadingView(message: "Loading messages...")
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
            .navigationTitle("messages.title".localized)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    filterButton
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.unreadCount > 0 {
                        markAllReadButton
                    }
                }
            }
            .task {
                if !viewModel.hasLoaded {
                    await viewModel.fetchMessages()
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
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
            }
        }
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
