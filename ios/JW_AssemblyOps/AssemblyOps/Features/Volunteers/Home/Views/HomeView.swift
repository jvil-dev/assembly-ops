//
//  HomeView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Home View
//
// Dashboard screen showing event overview and quick access to key info.
// Uses the app's design system with warm backgrounds and floating cards.
//
// Components:
//   - Event details card: Current event info
//   - Pending assignments card: Assignments awaiting response
//   - Latest message card: Recent message preview
//
// Features:
//   - Warm gradient background matching login screens
//   - Floating cards with layered shadows
//   - Staggered entrance animations
//   - Pull to refresh support
//
// Dependencies:
//   - AppState: Access to current volunteer and event info
//   - AppTheme: Design system tokens
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    // Event details
                    eventDetailsSection
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Pending assignments
                    pendingAssignmentsSection
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // Latest message
                    latestMessageSection
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("Home")
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Event Details

    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Section header
            Text("Event Details")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.themeColor)

            // Content
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                // Theme (if available)
                if let theme = appState.currentVolunteer?.eventTheme {
                    Text(theme)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(.primary)
                }

                // Venue
                if let venue = appState.currentVolunteer?.eventVenue {
                    HStack(spacing: 8) {
                        Image(systemName: "building.2")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        Text(venue)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                }

                // Department
                if let department = appState.currentVolunteer?.departmentName {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.shield.checkmark")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        Text(department)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Pending Assignments

    private var pendingAssignmentsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Section header
            HStack {
                Text("Pending Assignments")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.themeColor)

                Spacer()

                // Badge for pending count (if any)
                if PendingBadgeManager.shared.pendingCount > 0 {
                    Text("\(PendingBadgeManager.shared.pendingCount)")
                        .font(AppTheme.Typography.captionBold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.StatusColors.pending)
                        .clipShape(Capsule())
                }
            }

            // Empty state or content
            if PendingBadgeManager.shared.pendingCount == 0 {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 28))
                            .foregroundStyle(AppTheme.StatusColors.accepted)
                        Text("No pending assignments")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                    Spacer()
                }
                .padding(.vertical, AppTheme.Spacing.l)
            } else {
                // Show a prompt to view assignments
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(AppTheme.StatusColors.warning)
                    Text("You have assignments awaiting your response")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
                .padding(.vertical, AppTheme.Spacing.s)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Latest Message

    private var latestMessageSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Section header
            HStack {
                Text("Latest Message")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.themeColor)

                Spacer()

                // Unread badge (if any)
                if UnreadBadgeManager.shared.unreadCount > 0 {
                    Text("\(UnreadBadgeManager.shared.unreadCount)")
                        .font(AppTheme.Typography.captionBold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.StatusColors.info)
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Empty state
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "envelope.open")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text("No unread messages")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
                Spacer()
            }
            .padding(.vertical, AppTheme.Spacing.l)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState.shared)
}

#Preview("Dark Mode") {
    HomeView()
        .environmentObject(AppState.shared)
        .preferredColorScheme(.dark)
}
