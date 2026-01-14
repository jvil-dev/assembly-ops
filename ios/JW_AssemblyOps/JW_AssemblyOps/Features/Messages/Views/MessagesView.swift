//
//  MessagesView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 1/13/26.
//

// MARK: - Messages View
//
// Main view for displaying volunteer messages from overseers.
//
// Features:
//   - List of messages with unread indicators
//   - Pull to refresh
//   - Filter toggle (all vs unread only)
//   - Mark all as read button
//   - Navigation to message detail
//   - Loading, error, and empty states
//
// Dependencies:
//   - MessagesViewModel: State management
//   - MessageRowView: List row component
//   - MessageDetailView: Detail view
//   - EmptyMessagesView: Empty state
//   - LoadingView, ErrorView: Shared components
//
// Used by: MainTabView



import SwiftUI

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    
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
                    EmptyMessagesView(showUnreadOnly: viewModel.showUnreadOnly)
                } else {
                    messagesList
                }
            }
            .navigationTitle("Messages")
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
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                if !viewModel.hasLoaded {
                    await viewModel.fetchMessages()
                }
            }
        }
    }
    
    private var filterButton: some View {
        Button {
            viewModel.showUnreadOnly.toggle()
            HapticManager.shared.lightTap()
        } label: {
            Label(
                viewModel.showUnreadOnly ? "All" : "Unread",
                systemImage: viewModel.showUnreadOnly ? "envelope" : "envelope.badge"
            )
        }
    }
    
    private var markAllReadButton: some View {
        Button {
            Task {
                await viewModel.markAllAsRead()
            }
        } label: {
            Label("Mark All Read", systemImage: "checkmark.circle")
        }
    }
    
    private var messagesList: some View {
        List {
            ForEach(viewModel.filteredMessages) { message in
                NavigationLink(value: message) {
                    MessageRowView(message: message)
                }
            }
        }
        .listStyle(.plain)
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
