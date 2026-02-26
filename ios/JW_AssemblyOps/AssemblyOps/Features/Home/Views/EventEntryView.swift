//
//  EventEntryView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/25/26.
//

// MARK: - Event Entry View
//
// Context bridge between Events Hub and role-specific tab views.
// Receives an EventMembershipItem, sets up the appropriate session context,
// then presents OverseerTabView or VolunteerTabView.
//
// Navigation:
//   - Pushed from EventsHomeView via NavigationStack
//   - Standard back button returns to Events Hub
//   - Tab views hide the navigation bar to avoid double bars
//
// Context Setup:
//   - Overseer: OverseerSessionState.loadForEvent(membership)
//   - Volunteer: AppState.currentEventId = membership.eventId

import SwiftUI

struct EventEntryView: View {
    let membership: EventMembershipItem
    @EnvironmentObject private var appState: AppState
    @State private var isReady = false

    var body: some View {
        Group {
            if isReady {
                if membership.membershipType == .overseer {
                    OverseerTabView()
                        .environmentObject(appState)
                        .toolbar(.hidden, for: .navigationBar)
                } else {
                    VolunteerTabView()
                        .environmentObject(appState)
                        .toolbar(.hidden, for: .navigationBar)
                }
            } else {
                loadingView
            }
        }
        .task {
            await setupContext()
            isReady = true
        }
        .navigationTitle(membership.eventName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Context Setup

    private func setupContext() async {
        if membership.membershipType == .overseer {
            await OverseerSessionState.shared.loadForEvent(membership)
        } else {
            // Set volunteer context for HomeViewModel and other volunteer views
            appState.currentEventId = membership.eventId
            appState.hasVolunteerEventMembership = true
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            ProgressView()
                .tint(AppTheme.themeColor)
            Text("eventsHub.loading".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .themedBackground(scheme: colorScheme)
    }

    @Environment(\.colorScheme) private var colorScheme
}
