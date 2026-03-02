//
//  LanyardStatusView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/1/26.
//

// MARK: - Lanyard Status View
//
// Volunteer view showing today's lanyard status with pickup/return actions.
// Displays current status and provides toggle buttons.
//

import SwiftUI

struct LanyardStatusView: View {
    @StateObject private var viewModel = LanyardViewModel()
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    private var eventId: String? {
        appState.currentEventId
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                statusCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                actionsCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("lanyard.title".localized)
        .refreshable {
            if let eventId = eventId {
                await viewModel.loadMyStatus(eventId: eventId)
            }
        }
        .task {
            if let eventId = eventId {
                await viewModel.loadMyStatus(eventId: eventId)
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            statusIcon
            statusLabel
            statusDate
        }
        .frame(maxWidth: .infinity)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private var statusIcon: some View {
        let state = viewModel.myStatus?.status ?? .notPickedUp
        let icon: String
        let color: Color

        switch state {
        case .notPickedUp:
            icon = "lanyard"
            color = AppTheme.textTertiary(for: colorScheme)
        case .pickedUp:
            icon = "lanyard"
            color = AppTheme.StatusColors.accepted
        case .returned:
            icon = "checkmark.circle.fill"
            color = AppTheme.StatusColors.info
        }

        return Image(systemName: icon)
            .font(.system(size: 48))
            .foregroundStyle(color)
            .padding(.top, AppTheme.Spacing.m)
    }

    private var statusLabel: some View {
        let state = viewModel.myStatus?.status ?? .notPickedUp
        let text: String

        switch state {
        case .notPickedUp: text = "lanyard.status.notPickedUp".localized
        case .pickedUp: text = "lanyard.status.pickedUp".localized
        case .returned: text = "lanyard.status.returned".localized
        }

        return Text(text)
            .font(AppTheme.Typography.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
    }

    private var statusDate: some View {
        Text(viewModel.myStatus?.date ?? "lanyard.status.today".localized)
            .font(AppTheme.Typography.caption)
            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            .padding(.bottom, AppTheme.Spacing.s)
    }

    // MARK: - Actions Card

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "hand.tap", title: "lanyard.actions".localized)

            let state = viewModel.myStatus?.status ?? .notPickedUp

            if state == .notPickedUp {
                actionButton(
                    title: "lanyard.pickUp".localized,
                    icon: "arrow.up.circle.fill",
                    color: AppTheme.StatusColors.accepted
                ) {
                    if let eventId = eventId {
                        await viewModel.pickUp(eventId: eventId)
                    }
                }
            }

            if state == .pickedUp {
                actionButton(
                    title: "lanyard.return".localized,
                    icon: "arrow.down.circle.fill",
                    color: AppTheme.StatusColors.info
                ) {
                    if let eventId = eventId {
                        await viewModel.returnLanyard(eventId: eventId)
                    }
                }
            }

            if state == .returned {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.StatusColors.info)
                    Text("lanyard.allDone".localized)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.l)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
            HapticManager.shared.lightTap()
        } label: {
            HStack(spacing: AppTheme.Spacing.m) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Text(title)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(AppTheme.Spacing.m)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        LanyardStatusView()
            .environmentObject(AppState.shared)
    }
}
