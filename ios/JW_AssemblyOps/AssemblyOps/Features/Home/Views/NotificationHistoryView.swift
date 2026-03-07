//
//  NotificationHistoryView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/7/26.
//

// MARK: - Notification History View
//
// Full-screen list of all notifications for an event.
// Supports mark-as-read on tap, mark-all-read, and pagination.
//
// Used by: EventHomeView (NavigationLink from recent notifications card)

import SwiftUI

struct NotificationHistoryView: View {
    let eventId: String
    var accentColor: Color = AppTheme.themeColor

    @StateObject private var viewModel = NotificationHistoryViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.s) {
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    loadingState
                } else if viewModel.notifications.isEmpty {
                    emptyState
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                } else {
                    notificationsList
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.m)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle(NSLocalizedString("notifications.title", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.unreadCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.markAllRead(eventId: eventId) }
                    } label: {
                        Text(NSLocalizedString("notifications.markAllRead", comment: ""))
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(accentColor)
                    }
                }
            }
        }
        .refreshable {
            await viewModel.loadNotifications(eventId: eventId)
            await viewModel.loadUnreadCount(eventId: eventId)
        }
        .task {
            await viewModel.loadNotifications(eventId: eventId)
            await viewModel.loadUnreadCount(eventId: eventId)
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            ProgressView()
            Text(NSLocalizedString("notifications.loading", comment: ""))
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxl)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "bell.slash")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Text(NSLocalizedString("notifications.empty", comment: ""))
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)
            Text(NSLocalizedString("notifications.empty.subtitle", comment: ""))
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxl)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Notifications List

    private var notificationsList: some View {
        LazyVStack(spacing: AppTheme.Spacing.s) {
            ForEach(Array(viewModel.notifications.enumerated()), id: \.element.id) { index, notification in
                notificationRow(notification)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.03)
                    .onAppear {
                        if notification.id == viewModel.notifications.last?.id {
                            Task { await viewModel.loadMore(eventId: eventId) }
                        }
                    }
            }

            if viewModel.isLoading && !viewModel.notifications.isEmpty {
                ProgressView()
                    .padding(.vertical, AppTheme.Spacing.m)
            }
        }
    }

    private func notificationRow(_ notification: NotificationItem) -> some View {
        Button {
            HapticManager.shared.lightTap()
            Task { await viewModel.markRead(notification) }
        } label: {
            HStack(alignment: .top, spacing: AppTheme.Spacing.m) {
                Image(systemName: notification.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(notification.isRead
                        ? AppTheme.textTertiary(for: colorScheme)
                        : accentColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(notification.isRead
                            ? AppTheme.Typography.subheadline
                            : AppTheme.Typography.bodyMedium)
                        .foregroundStyle(.primary)

                    Text(notification.body)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .lineLimit(2)

                    Text(notification.timeAgo)
                        .font(AppTheme.Typography.captionSmall)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                Spacer()

                if !notification.isRead {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                }
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }
}
