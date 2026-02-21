//
//  MessageDetailView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/13/26.
//

// MARK: - Message Detail View
//
// Full-screen view for reading a single message.
//
// Features:
//   - Themed card layout with recipient type badge
//   - Subject, sender, and timestamp
//   - Full message body
//   - Auto-marks message as read on appear with haptic
//
// Used by: MessagesView (navigation destination)

import SwiftUI

struct MessageDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    let message: Message
    let onMarkRead: () async -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Header card
                headerCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                // Body card
                bodyCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("messages.detail.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !message.isRead {
                HapticManager.shared.lightTap()
                await onMarkRead()
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Type badge
            HStack(spacing: 6) {
                Image(systemName: message.recipientType.icon)
                Text(message.recipientType.displayName)
            }
            .font(AppTheme.Typography.caption)
            .foregroundStyle(recipientColor)
            .padding(.horizontal, 10)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(recipientColor.opacity(0.12))
            .clipShape(Capsule())

            // Subject
            Text(message.displaySubject)
                .font(AppTheme.Typography.title)
                .foregroundStyle(.primary)

            // Meta info
            HStack {
                if let sender = message.senderName {
                    Label(sender, systemImage: "person")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                Text(message.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Body Card

    private var bodyCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "text.alignleft")
                    .foregroundStyle(AppTheme.themeColor)
                Text("messages.detail.body".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text(message.body)
                .font(AppTheme.Typography.body)
                .foregroundStyle(.primary)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private var recipientColor: Color {
        switch message.recipientType {
        case .volunteer: return AppTheme.themeColor
        case .department: return .blue
        case .event: return .purple
        }
    }
}

#Preview {
    NavigationStack {
        MessageDetailView(message: .preview) {
            // Mark read action
        }
    }
}
