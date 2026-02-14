//
//  OverseerMessagesView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/9/26.
//

// MARK: - Overseer Messages View
//
// Main messaging hub for overseers with tabs for sent messages and check-in stats.
// Provides unified interface for communication and volunteer monitoring.
//
// Tabs:
//   - Messages: View sent messages history (SentMessagesView)
//   - Stats: View check-in statistics by session (CheckInStatsView)
//
// Features:
//   - Tab navigation between messages and stats
//   - Floating compose button (always visible)
//   - Launches MessageComposeView for new messages
//   - Badge indicators for unread messages (future enhancement)
//
// Navigation:
//   - Accessed from OverseerTabView or OverseerDashboardView
//   - Child tabs handle their own data loading and refresh

import SwiftUI

struct OverseerMessagesView: View {
    @StateObject private var viewModel = SentMessagesViewModel()
    @ObservedObject private var sessionState: OverseerSessionState = .shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showComposeSheet = false
    @State private var composeRecipientType: MessageRecipientType? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        // Compose button card
                        composeCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                        // Quick actions
                        quickActionsCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                        // Recent sent messages
                        if !viewModel.messages.isEmpty {
                            recentMessagesCard
                                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                        }
                    }
                    .screenPadding()
                    .padding(.top, AppTheme.Spacing.l)
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showComposeSheet) {
                MessageComposeView(initialRecipientType: composeRecipientType)
            }
            .task {
                // Load recent messages
                await viewModel.fetchMessages()
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Compose Card
    private var composeCard: some View {
        Button {
            HapticManager.shared.lightTap()
            composeRecipientType = nil  // Reset to default (volunteer)
            showComposeSheet = true
        } label: {
            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(AppTheme.themeColor)
                        .frame(width: 56, height: 56)

                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Compose Message")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)

                    Text("Send a message to volunteers")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Actions Card
    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("QUICK ACTIONS")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Department message button
            if let departmentName = sessionState.selectedDepartment?.name ?? sessionState.claimedDepartment?.name {
                Button {
                    HapticManager.shared.lightTap()
                    composeRecipientType = .department
                    showComposeSheet = true
                } label: {
                    HStack {
                        Image(systemName: "person.3")
                            .foregroundStyle(AppTheme.themeColor)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Message Department")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(.primary)
                            Text(departmentName)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .cornerRadius(AppTheme.CornerRadius.small)
                }
                .buttonStyle(.plain)
            }

            // Event broadcast button (only for App Admins)
            if sessionState.isEventOverseer, let eventName = sessionState.selectedEvent?.name {
                Button {
                    HapticManager.shared.lightTap()
                    composeRecipientType = .event
                    showComposeSheet = true
                } label: {
                    HStack {
                        Image(systemName: "megaphone")
                            .foregroundStyle(.purple)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Event Broadcast")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(.primary)
                            Text(eventName)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .cornerRadius(AppTheme.CornerRadius.small)
                }
                .buttonStyle(.plain)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Recent Messages Card
    private var recentMessagesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Section header with "View All" link
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(AppTheme.themeColor)
                    Text("RECENT MESSAGES")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                Spacer()

                NavigationLink(destination: SentMessagesView()) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(AppTheme.Typography.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(AppTheme.themeColor)
                }
            }

            // Recent messages preview (max 3)
            ForEach(Array(viewModel.messages.prefix(3))) { message in
                NavigationLink(destination: SentMessagesView()) {
                    RecentMessageRow(message: message, colorScheme: colorScheme)
                }
                .buttonStyle(.plain)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }
}

// MARK: - Recent Message Row
private struct RecentMessageRow: View {
    let message: SentMessageItem
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Icon based on recipient type
            ZStack {
                Circle()
                    .fill(recipientColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: recipientIcon)
                    .foregroundStyle(recipientColor)
            }

            // Message info
            VStack(alignment: .leading, spacing: 4) {
                if let subject = message.subject, !subject.isEmpty {
                    Text(subject)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                } else {
                    Text(message.body)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Text(message.recipientTypeDisplayName)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                    if let recipientName = message.recipientName {
                        Text("•")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        Text(recipientName)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Time ago
            Text(timeAgo)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
        }
        .padding(AppTheme.Spacing.m)
        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
        .cornerRadius(AppTheme.CornerRadius.small)
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
