//
//  EventSetupView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/31/26.
//

// MARK: - Event Setup View
//
// Router view presenting two options for overseers without events:
//   1. Activate Event - Create a new event from a template
//   2. Join Event - Join an existing event with a join code
//
// Shown after profile setup when overseer has no events.
// Cannot be dismissed - must complete one of the flows to proceed.
//

import SwiftUI

struct EventSetupView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = EventSetupViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showActivateEvent = false
    @State private var showJoinEvent = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Header
                    headerSection
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Activate Event card
                    activateEventCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // Divider
                    dividerRow
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

                    // Join Event card
                    joinEventCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("Get Started")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showActivateEvent) {
                EventTemplateListView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $showJoinEvent) {
                JoinEventView(viewModel: viewModel)
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.themeColor)

            Text("Set Up Your Event")
                .font(AppTheme.Typography.title)
                .fontWeight(.bold)

            Text("Create a new event from a template or join an existing one with a code from the Event Overseer.")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, AppTheme.Spacing.l)
    }

    // MARK: - Activate Event Card

    private var activateEventCard: some View {
        Button {
            showActivateEvent = true
            HapticManager.shared.lightTap()
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                HStack(spacing: AppTheme.Spacing.m) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.themeColor.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.themeColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Activate Event")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(colorScheme == .dark ? .white : .primary)

                        Text("Event Overseer")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                Text("Create a new event from an available template. You'll become the Event Overseer and receive a join code to share.")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.leading)
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Divider

    private var dividerRow: some View {
        HStack {
            Rectangle()
                .fill(AppTheme.dividerColor(for: colorScheme))
                .frame(height: 1)
            Text("or")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                .padding(.horizontal, AppTheme.Spacing.m)
            Rectangle()
                .fill(AppTheme.dividerColor(for: colorScheme))
                .frame(height: 1)
        }
    }

    // MARK: - Join Event Card

    private var joinEventCard: some View {
        Button {
            showJoinEvent = true
            HapticManager.shared.lightTap()
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                HStack(spacing: AppTheme.Spacing.m) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.StatusColors.info.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "person.badge.key.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.StatusColors.info)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Join Event")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(colorScheme == .dark ? .white : .primary)

                        Text("Department Overseer")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                Text("Join an event using a code from the Event Overseer. You can then claim a department to manage.")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.leading)
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Light") {
    EventSetupView()
        .environmentObject(AppState.shared)
}

#Preview("Dark") {
    EventSetupView()
        .environmentObject(AppState.shared)
        .preferredColorScheme(.dark)
}
