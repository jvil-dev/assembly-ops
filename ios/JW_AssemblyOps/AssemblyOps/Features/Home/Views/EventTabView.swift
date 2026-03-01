//
//  EventTabView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/26/26.
//

// MARK: - Event Tab View
//
// Unified tab navigation container for all users within an event context.
// Replaces the separate OverseerTabView and VolunteerTabView with a
// single role-aware container.
//
// Tabs:
//   - Home: EventHomeView — event details, department tag, upcoming assignments
//   - [Department]: DepartmentTabRouter — department-specific features by role
//   - Assignments: Coverage matrix (overseer) or schedule list (volunteer)
//   - Messages: Full messaging (overseer) or inbox (volunteer)
//
// Features:
//   - Dynamic department tab label from membership data
//   - Department-colored tab tint
//   - OfflineBanner at top when network lost
//   - Badge counts on Assignments (volunteer) and Messages (both)
//   - Scene phase badge refresh management
//   - Context setup from EventMembershipItem (absorbed from EventEntryView)
//

import SwiftUI

/// Tab identifiers for programmatic tab switching
enum EventTab: Int {
    case home, department, assignments, messages
}

struct EventTabView: View {
    let membership: EventMembershipItem

    @EnvironmentObject private var appState: AppState
    @ObservedObject private var sessionState = EventSessionState.shared
    @ObservedObject private var messageBadgeManager = UnreadBadgeManager.shared
    @ObservedObject private var pendingBadgeManager = PendingBadgeManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: EventTab = .home
    @State private var isReady = false

    var isOverseer: Bool {
        membership.membershipType == .overseer
    }

    private var departmentTabLabel: String {
        membership.departmentName ?? "Department"
    }

    private var departmentTabIcon: String {
        guard let type = membership.departmentType else { return "building.2" }
        switch type.uppercased() {
        case "PARKING": return "car"
        case "ATTENDANT": return "person.badge.shield.checkmark"
        case "AUDIO": return "speaker.wave.3"
        case "VIDEO": return "video"
        case "STAGE": return "light.overhead.left"
        case "CLEANING": return "sparkles"
        case "COMMITTEE": return "person.3"
        case "FIRST_AID", "FIRSTAID": return "cross"
        case "BAPTISM": return "drop"
        case "INFORMATION", "INFORMATION_VOLUNTEER_SERVICE": return "info.circle"
        case "ACCOUNTS": return "dollarsign.circle"
        case "INSTALLATION": return "hammer"
        case "LOST_FOUND", "LOST_AND_FOUND", "LOST_FOUND_CHECKROOM": return "tray"
        case "ROOMING": return "bed.double"
        case "TRUCKING", "TRUCKING_EQUIPMENT": return "truck.box"
        default: return "building.2"
        }
    }

    private var tabTintColor: Color {
        if let deptType = membership.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    var body: some View {
        VStack(spacing: 0) {
            eventHeaderBar

            Group {
                if isReady {
                    VStack(spacing: 0) {
                        OfflineBanner()
                            .animation(.easeInOut, value: NetworkMonitor.shared.isConnected)

                        TabView(selection: $selectedTab) {
                            // Tab 1: Home
                            Group {
                                if isOverseer {
                                    EventHomeView(membership: membership)
                                } else {
                                    HomeView(switchToTab: { selectedTab = $0 })
                                }
                            }
                            .environmentObject(appState)
                            .tabItem {
                                Label("tab.home".localized, systemImage: "house")
                            }
                            .tag(EventTab.home)

                            // Tab 2: Department (dynamic label)
                            DepartmentTabRouter(membership: membership)
                                .environmentObject(appState)
                                .tabItem {
                                    Label(departmentTabLabel, systemImage: departmentTabIcon)
                                }
                                .tag(EventTab.department)

                            // Tab 3: Assignments
                            Group {
                                if isOverseer {
                                    AssignmentsView()
                                } else {
                                    AssignmentsListView()
                                }
                            }
                            .environmentObject(appState)
                            .tabItem {
                                Label("tab.schedule".localized, systemImage: isOverseer ? "tablecells" : "calendar")
                            }
                            .badge(isOverseer ? 0 : pendingBadgeManager.pendingCount)
                            .tag(EventTab.assignments)

                            // Tab 4: Messages
                            Group {
                                if isOverseer {
                                    OverseerMessagesView()
                                } else {
                                    MessagesView()
                                }
                            }
                            .environmentObject(appState)
                            .tabItem {
                                Label("tab.messages".localized, systemImage: "envelope")
                            }
                            .badge(messageBadgeManager.unreadCount)
                            .tag(EventTab.messages)
                        }
                        .tint(tabTintColor)
                    }
                } else {
                    loadingView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await setupContext()
            isReady = true
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                messageBadgeManager.startRefreshing()
                pendingBadgeManager.startRefreshing()
            case .inactive, .background:
                messageBadgeManager.stopRefreshing()
                pendingBadgeManager.stopRefreshing()
            @unknown default:
                break
            }
        }
        .onAppear {
            if scenePhase == .active {
                messageBadgeManager.startRefreshing()
                pendingBadgeManager.startRefreshing()
            }
        }
    }

    // MARK: - Event Header Bar

    private var eventHeaderBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppTheme.Spacing.m) {
                Button {
                    HapticManager.shared.lightTap()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.themeColor)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        )
                }
                .accessibilityLabel("eventTab.back".localized)

                Text(membership.eventName)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    .lineLimit(1)

                Spacer()

                if let deptType = membership.departmentType {
                    Circle()
                        .fill(DepartmentColor.color(for: deptType))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.l)
            .frame(height: 44)
            .background(AppTheme.cardBackground(for: colorScheme))

            Rectangle()
                .fill(AppTheme.dividerColor(for: colorScheme))
                .frame(height: 1)
        }
    }

    // MARK: - Context Setup

    private func setupContext() async {
        if membership.membershipType == .overseer {
            EventSessionState.shared.loadForEvent(membership)
        } else {
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
}

#Preview {
    EventTabView(
        membership: EventMembershipItem(
            id: "1",
            eventId: "1",
            eventName: "2026 Circuit Assembly",
            eventType: "CIRCUIT_ASSEMBLY_CO",
            theme: nil,
            venue: "Assembly Hall",
            address: "123 Main St",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 2),
            volunteerCount: 45,
            membershipType: .overseer,
            overseerRole: "DEPARTMENT_OVERSEER",
            departmentId: "d1",
            departmentName: "Attendant",
            departmentType: "ATTENDANT",
            departmentAccessCode: "ABC123",
            eventVolunteerId: nil,
            volunteerId: nil
        )
    )
    .environmentObject(AppState.shared)
}
