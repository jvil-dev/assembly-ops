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
//   - Reply button (opens conversation if exists)
//   - Delete action
//   - Auto-marks message as read on appear with haptic
//
// Used by: MessagesView (navigation destination)

import SwiftUI

struct MessageDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false
    @State private var showDeleteConfirm = false

    let message: Message
    let onMarkRead: () async -> Void
    var onDelete: (() async -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Header card
                headerCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                // Body card
                bodyCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                // Actions card
                if message.conversationId != nil || onDelete != nil {
                    actionsCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                }
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
        .alert("messages.delete.confirm".localized, isPresented: $showDeleteConfirm) {
            Button("messages.delete".localized, role: .destructive) {
                Task {
                    await onDelete?()
                    dismiss()
                }
            }
            Button("general.cancel".localized, role: .cancel) {}
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

    // MARK: - Actions Card

    private var actionsCard: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            // Reply button (if part of a conversation)
            if let conversationId = message.conversationId {
                NavigationLink {
                    ConversationDetailView(
                        conversationId: conversationId,
                        otherParticipantName: message.senderName ?? "Unknown",
                        currentUserId: AppState.shared.currentVolunteer?.id ?? AppState.shared.currentOverseer?.id
                    )
                } label: {
                    Label("messages.reply".localized, systemImage: "arrowshape.turn.up.left")
                        .font(AppTheme.Typography.body.weight(.medium))
                        .foregroundStyle(AppTheme.themeColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.m)
                        .background(AppTheme.themeColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                }
            }

            // Delete button
            if onDelete != nil {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("messages.delete".localized, systemImage: "trash")
                        .font(AppTheme.Typography.body.weight(.medium))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.m)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private var recipientColor: Color {
        switch message.recipientType {
        case .volunteer: return AppTheme.themeColor
        case .department: return .blue
        case .event: return .purple
        case .admin: return .orange
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
