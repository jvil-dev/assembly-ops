//
//  EmptyMessagesView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/13/26.
//

// MARK: - Empty Messages View
//
// Empty state shown when no messages are available.
//
// States:
//   - No messages: "No Messages Yet" with envelope icon
//   - No unread (filtered): "No Unread Messages" with checkmark
//
// Dependencies:
//   - showUnreadOnly: Boolean to determine which state to show
//
// Used by: MessagesView



import SwiftUI

struct EmptyMessagesView: View {
    let showUnreadOnly: Bool
    
    var body: some View {
        ContentUnavailableView(
            showUnreadOnly ? "No Unread Messages" : "No Messages Yet",
            systemImage: showUnreadOnly ? "checkmark.circle" : "envelope",
            description: Text(
                showUnreadOnly 
                    ? "You're all caught up!"
                    : "Messages from your overseer will appear here."
            )
        )
    }
}

#Preview {
    EmptyMessagesView(showUnreadOnly: false)
}

#Preview("Unread Filter") {
    EmptyMessagesView(showUnreadOnly: true)
}
