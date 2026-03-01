//
//  EventHomeView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/26/26.
//

// MARK: - Event Home View (Overseer)
//
// Home tab for overseers inside an event context.
// Shows event details and today's department assignments.
//
// Sections:
//   - Settings circle (top-left toolbar)
//   - Event details banner (theme + type badge, venue, dates, volunteers)
//   - Department tag showing user's department + role
//   - Today's assignments — posts with assigned volunteers for today's sessions
//

import SwiftUI

struct EventHomeView: View {
    let membership: EventMembershipItem

    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var coverageVM = CoverageMatrixViewModel()
    @State private var hasAppeared = false
    @State private var showSettings = false

    private var departmentColor: Color {
        if let deptType = membership.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
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
                    // Event details banner
                    eventDetailsCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Department tag
                    if let deptName = membership.departmentName {
                        departmentTagCard(name: deptName)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                    }

                    // Today's assignments
                    todaysAssignmentsSection
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
            .task {
                coverageVM.departmentId = membership.departmentId
                await coverageVM.loadCoverage()
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
            // Theme + Event Type badge
            Text(membership.themeBadgeText)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(departmentColor)
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(departmentColor.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

            // Info rows
            HStack(spacing: AppTheme.Spacing.l) {
                infoColumn(icon: "mappin.circle", text: membership.venue)
                Divider().frame(height: 32)
                infoColumn(icon: "calendar", text: dateRangeString)
                Divider().frame(height: 32)
                infoColumn(icon: "person.3", text: "\(membership.volunteerCount)")
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private func infoColumn(icon: String, text: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Text(text)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
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

    // MARK: - Today's Assignments

    private var todaySessions: [CoverageSession] {
        let calendar = Calendar.current
        return coverageVM.sessions.filter { calendar.isDateInToday($0.date) }
    }

    @ViewBuilder
    private var todaysAssignmentsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(departmentColor)
                Text("Today's Schedule")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            if coverageVM.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(departmentColor)
                    Spacer()
                }
                .padding(.vertical, AppTheme.Spacing.l)
            } else if todaySessions.isEmpty {
                noSessionsPlaceholder
            } else {
                ForEach(todaySessions) { session in
                    sessionAssignmentsCard(session: session)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private var noSessionsPlaceholder: some View {
        HStack {
            Spacer()
            VStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "calendar.badge.minus")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                Text("No sessions scheduled for today")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.l)
    }

    private func sessionAssignmentsCard(session: CoverageSession) -> some View {
        let sessionSlots = coverageVM.slots(for: session.id)

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            // Session header
            HStack {
                Text(session.name)
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text("·")
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

                Text(sessionTimeString(session))
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                Spacer()

                // Fill status
                let filledCount = sessionSlots.filter { $0.isFilled }.count
                Text("\(filledCount)/\(sessionSlots.count)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(filledCount == sessionSlots.count
                        ? AppTheme.StatusColors.accepted
                        : AppTheme.StatusColors.pending)
            }
            .padding(.bottom, 2)

            // Post rows
            ForEach(sessionSlots, id: \.id) { slot in
                postRow(slot: slot)
            }
        }
        .padding(AppTheme.Spacing.m)
        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
    }

    private func postRow(slot: CoverageSlot) -> some View {
        HStack(spacing: AppTheme.Spacing.s) {
            // Fill indicator dot
            Circle()
                .fill(slot.isFilled
                    ? AppTheme.StatusColors.accepted
                    : (slot.assignments.isEmpty ? AppTheme.StatusColors.declined : AppTheme.StatusColors.pending))
                .frame(width: 8, height: 8)

            // Post name
            VStack(alignment: .leading, spacing: 2) {
                Text(slot.postName)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.primary)

                // Volunteer names or unfilled indicator
                if slot.assignments.isEmpty {
                    Text("Unfilled")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.StatusColors.declined)
                } else {
                    Text(slot.assignments.map { volunteerDisplayName($0.volunteer) }.joined(separator: ", "))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Capacity badge
            Text("\(slot.filled)/\(slot.capacity)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(slot.isFilled
                    ? AppTheme.StatusColors.accepted
                    : AppTheme.textTertiary(for: colorScheme))
        }
        .padding(.vertical, 2)
    }

    // MARK: - Helpers

    private func volunteerDisplayName(_ v: CoverageVolunteer) -> String {
        "\(v.firstName) \(v.lastName.prefix(1))."
    }

    private func sessionTimeString(_ session: CoverageSession) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: session.startTime)
    }

    private var departmentIcon: String {
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
}

#Preview {
    EventHomeView(
        membership: EventMembershipItem(
            id: "1", eventId: "1",
            eventName: "2026 Circuit Assembly",
            eventType: "CIRCUIT_ASSEMBLY_CO",
            theme: "Declare the Good News!",
            venue: "Assembly Hall", address: "123 Main St",
            startDate: Date(), endDate: Date().addingTimeInterval(86400 * 2),
            volunteerCount: 45, membershipType: .overseer,
            overseerRole: "DEPARTMENT_OVERSEER",
            departmentId: "d1", departmentName: "Attendant",
            departmentType: "ATTENDANT",
            departmentAccessCode: "ABC123",
            eventVolunteerId: nil, volunteerId: nil
        )
    )
    .environmentObject(AppState.shared)
}
