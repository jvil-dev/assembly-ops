//
//  EventsHomeView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/25/26.
//

// MARK: - Events Home View
//
// Main hub for all logged-in users. Shows event cards grouped by
// Active / Upcoming / Past. Tapping a card pushes into the
// unified tab view via EventTabView.
//
// Navigation:
//   - Top-left: Profile avatar → SettingsView (sheet)
//   - Top-right: "+" → BrowseEventsView (push)
//   - Card tap → EventTabView (push)
//
// Dependencies:
//   - EventsHomeViewModel: Loads myAllEvents query
//   - AppState: Current user info for avatar

import SwiftUI

// MARK: - Pop-to-Root Environment Key

private struct PopToRootKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var popToRoot: () -> Void {
        get { self[PopToRootKey.self] }
        set { self[PopToRootKey.self] = newValue }
    }
}

struct EventsHomeView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = EventsHomeViewModel()
    @ObservedObject private var pushManager = PushNotificationManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showSettings = false
    @State private var showError = false
    @State private var navigationStackId = UUID()
    @State private var deepLinkMembership: EventMembershipItem?

    var body: some View {
        NavigationStack {
            mainContent
        }
        .id(navigationStackId)
        .onChange(of: pushManager.pendingDeepLink) { _, deepLink in
            guard let deepLink else { return }
            if let membership = viewModel.findMembership(eventId: deepLink.eventId) {
                deepLinkMembership = membership
            } else {
                viewModel.refresh()
            }
        }
        .onChange(of: viewModel.sections) { _, _ in
            guard let deepLink = pushManager.pendingDeepLink,
                  let membership = viewModel.findMembership(eventId: deepLink.eventId) else { return }
            deepLinkMembership = membership
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        Group {
            if viewModel.isLoading && viewModel.sections.isEmpty {
                loadingView
            } else if viewModel.isEmpty {
                emptyState
            } else {
                eventsList
            }
        }
        .themedBackground(scheme: colorScheme)
        .navigationDestination(item: $deepLinkMembership) { item in
            EventTabView(membership: item)
                .environmentObject(appState)
        }
        .navigationTitle("eventsHub.title".localized)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                profileAvatarButton
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                plusButton
            }
        }
        .refreshable {
            viewModel.refresh()
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) { hasAppeared = true }
            viewModel.load()
        }
        .onChange(of: viewModel.errorMessage) { _, error in
            showError = error != nil
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(appState)
        }
    }

    // MARK: - Events List

    private var eventsList: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                ForEach(viewModel.sections) { section in
                    sectionBlock(section)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }

    private func sectionBlock(_ section: EventSection) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Section header
            Text(section.title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.leading, 4)

            ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                NavigationLink {
                    EventTabView(membership: item)
                        .environmentObject(appState)
                } label: {
                    EventMembershipCard(item: item, colorScheme: colorScheme)
                }
                .buttonStyle(.plain)
                .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.05)
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                ForEach(0..<3, id: \.self) { _ in
                    loadingCard
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
        }
    }

    private var loadingCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.textTertiary(for: colorScheme).opacity(0.3))
                    .frame(width: 110, height: 12)
                Spacer()
            }
            RoundedRectangle(cornerRadius: 4)
                .fill(AppTheme.textTertiary(for: colorScheme).opacity(0.3))
                .frame(width: 200, height: 18)
            RoundedRectangle(cornerRadius: 4)
                .fill(AppTheme.textTertiary(for: colorScheme).opacity(0.3))
                .frame(width: 160, height: 14)
            RoundedRectangle(cornerRadius: 4)
                .fill(AppTheme.textTertiary(for: colorScheme).opacity(0.3))
                .frame(width: 130, height: 14)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .redacted(reason: .placeholder)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.15 : 0.08))
                    .frame(width: 96, height: 96)
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(AppTheme.themeColor)
            }
            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

            VStack(spacing: AppTheme.Spacing.s) {
                Text("eventsHub.empty.title".localized)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

                Text("eventsHub.empty.subtitle".localized)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

            NavigationLink {
                BrowseEventsView()
                    .environmentObject(appState)
                    .environment(\.popToRoot, popToRootAndRefresh)
            } label: {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                    Text("eventsHub.browse".localized)
                        .font(AppTheme.Typography.bodyMedium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.ButtonHeight.large)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                        .fill(AppTheme.themeColor)
                )
                .foregroundStyle(.white)
            }
            .screenPadding()
            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.screenEdge)
    }

    // MARK: - Toolbar Buttons

    private var profileAvatarButton: some View {
        Button {
            showSettings = true
            HapticManager.shared.lightTap()
        } label: {
            ZStack {
                Circle()
                    .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.25 : 0.12))
                    .frame(width: 34, height: 34)
                Text(appState.currentUser?.initials ?? "?")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.themeColor)
            }
        }
        .accessibilityLabel("eventsHub.a11y.profile".localized)
    }

    private var plusButton: some View {
        NavigationLink {
            BrowseEventsView()
                .environmentObject(appState)
                .environment(\.popToRoot, popToRootAndRefresh)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.themeColor)
        }
        .accessibilityLabel("eventsHub.a11y.browse".localized)
    }

    // MARK: - Pop to Root

    private func popToRootAndRefresh() {
        deepLinkMembership = nil
        navigationStackId = UUID()
        viewModel.refresh()
    }
}

#Preview {
    EventsHomeView()
        .environmentObject(AppState.shared)
}
