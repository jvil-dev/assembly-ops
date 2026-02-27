//
//  EventHomeView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/26/26.
//

// MARK: - Event Home View
//
// Unified home tab for all users inside an event context.
// Shows event-level information and upcoming assignments.
//
// Sections:
//   - Settings circle (top-left toolbar)
//   - Event details card (name, venue, dates, type)
//   - Department badge/tag showing user's department
//   - Upcoming assignments preview
//   - Future: event-wide cross-department stats
//
// This view does NOT contain overseer management features —
// those live in the Department tab (DepartmentTabRouter).
//

import SwiftUI

struct EventHomeView: View {
    let membership: EventMembershipItem

    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showSettings = false

    private var departmentColor: Color {
        if let deptType = membership.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    private var eventTypeDisplay: String {
        switch membership.eventType.uppercased() {
        case "CIRCUIT_ASSEMBLY", "CIRCUIT_ASSEMBLY_CO":
            return "Circuit Assembly"
        case "REGIONAL_CONVENTION":
            return "Regional Convention"
        case "SPECIAL_CONVENTION":
            return "Special Convention"
        default:
            return membership.eventType
        }
    }

    private var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let start = formatter.string(from: membership.startDate)
        let end = formatter.string(from: membership.endDate)
        return "\(start) – \(end)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    // Event details card
                    eventDetailsCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Department tag
                    if let deptName = membership.departmentName {
                        departmentTagCard(name: deptName)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                    }

                    // Upcoming assignments placeholder
                    upcomingAssignmentsCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.10)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle(membership.eventName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    settingsButton
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(appState)
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Settings Button

    private var settingsButton: some View {
        Button {
            showSettings = true
            HapticManager.shared.lightTap()
        } label: {
            ZStack {
                Circle()
                    .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.25 : 0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: "gearshape")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.themeColor)
            }
        }
    }

    // MARK: - Event Details Card

    private var eventDetailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(departmentColor)
                Text("Event Details")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                // Event type badge
                Text(eventTypeDisplay)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(departmentColor)
                    .padding(.horizontal, AppTheme.Spacing.s)
                    .padding(.vertical, 4)
                    .background(departmentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

                // Venue
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "mappin.circle")
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .frame(width: 20)
                    Text(membership.venue)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(.primary)
                }

                // Dates
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "clock")
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .frame(width: 20)
                    Text(dateRangeString)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(.primary)
                }

                // Volunteer count
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "person.3")
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .frame(width: 20)
                    Text("\(membership.volunteerCount) volunteers")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(.primary)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Department Tag Card

    private func departmentTagCard(name: String) -> some View {
        HStack(spacing: AppTheme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(departmentColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: departmentIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(departmentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Your Department")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                Text(name)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
            }

            Spacer()

            Text(membership.membershipType == .overseer ? "Overseer" : "Volunteer")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(departmentColor)
                .padding(.horizontal, AppTheme.Spacing.s)
                .padding(.vertical, 4)
                .background(departmentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Upcoming Assignments Card

    private var upcomingAssignmentsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(departmentColor)
                Text("Upcoming Assignments")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            HStack {
                Spacer()
                VStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "calendar")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text("View your assignments in the Assignments tab")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                }
                Spacer()
            }
            .padding(.vertical, AppTheme.Spacing.l)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Helpers

    private var departmentIcon: String {
        guard let type = membership.departmentType else { return "building.2" }
        switch type.uppercased() {
        case "PARKING": return "car"
        case "ATTENDANT": return "person.badge.shield.checkmark"
        case "AUDIO_VIDEO", "AV": return "video"
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
}
