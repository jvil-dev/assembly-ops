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
// Used by: MessagesView

import SwiftUI

struct EmptyMessagesView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    let showUnreadOnly: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Spacer()

            Image(systemName: showUnreadOnly ? "checkmark.circle" : "envelope")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Text(showUnreadOnly ? "messages.empty.unread.title".localized : "messages.empty.title".localized)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text(showUnreadOnly
                ? "messages.empty.unread.subtitle".localized
                : "messages.empty.subtitle".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppTheme.Spacing.screenEdge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }
}

#Preview {
    EmptyMessagesView(showUnreadOnly: false)
}

#Preview("Unread Filter") {
    EmptyMessagesView(showUnreadOnly: true)
}
