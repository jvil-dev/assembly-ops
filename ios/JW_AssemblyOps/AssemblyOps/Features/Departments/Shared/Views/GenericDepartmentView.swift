//
//  GenericDepartmentView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/26/26.
//

// MARK: - Generic Department View
//
// Placeholder view for departments without specific implementations yet.
// Used by DepartmentTabRouter for all departments except Attendant.
//
// Overseer view:
//   - Volunteer management (list, add, join requests)
//   - Department settings navigation
//   - Check-in stats
//   - Access code display
//
// Volunteer view:
//   - Department info card
//   - "Features coming soon" placeholder
//

import SwiftUI

struct GenericDepartmentView: View {
    let membership: EventMembershipItem

    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    private var isOverseer: Bool {
        membership.membershipType == .overseer
    }

    private var departmentColor: Color {
        if let deptType = membership.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                if isOverseer {
                    overseerContent
                } else {
                    volunteerContent
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle(membership.departmentName ?? "Department")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Overseer Content

    @ViewBuilder
    private var overseerContent: some View {
        // Volunteer management
        volunteersCard
            .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

        // Department settings
        if let dept = sessionState.claimedDepartment {
            departmentSettingsCard(department: dept)
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
        }

        // Join requests
        if let eventId = sessionState.selectedEvent?.id {
            joinRequestsCard(eventId: eventId)
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.10)
        }

        // Access code
        if let dept = sessionState.claimedDepartment, let code = dept.accessCode {
            accessCodeCard(code: code)
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
        }

        // Department-specific features placeholder
        comingSoonCard
            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.20)
    }

    // MARK: - Volunteer Content

    @ViewBuilder
    private var volunteerContent: some View {
        // Department info
        departmentInfoCard
            .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

        // Coming soon
        comingSoonCard
            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
    }

    // MARK: - Volunteers Card

    private var volunteersCard: some View {
        NavigationLink(destination: VolunteerListView()) {
            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(departmentColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "person.3")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(departmentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Volunteers")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                    Text("Manage your department's volunteers")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Department Settings Card

    private func departmentSettingsCard(department: DepartmentSummary) -> some View {
        NavigationLink(destination: DepartmentSettingsView(departmentId: department.id)) {
            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(departmentColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "gearshape.2")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(departmentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("departmentSettings.title".localized)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                    Text(department.name)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Join Requests Card

    private func joinRequestsCard(eventId: String) -> some View {
        NavigationLink(destination: JoinRequestsView(eventId: eventId)) {
            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(AppTheme.StatusColors.pendingBackground)
                        .frame(width: 40, height: 40)
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.StatusColors.pending)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("overseer.joinRequests.title".localized)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                    Text("overseer.joinRequests.subtitle".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Access Code Card

    private func accessCodeCard(code: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "key")
                    .foregroundStyle(departmentColor)
                Text("Access Code")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            HStack {
                Text(code)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .tracking(4)

                Spacer()

                Button {
                    UIPasteboard.general.string = code
                    HapticManager.shared.success()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(departmentColor)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Department Info Card

    private var departmentInfoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "building.2")
                    .foregroundStyle(departmentColor)
                Text("Department Info")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text(membership.departmentName ?? "Department")
                .font(AppTheme.Typography.title)
                .foregroundStyle(.primary)

            Text("You are a volunteer in this department.")
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Coming Soon Card

    private var comingSoonCard: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 32))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Text("Department-specific features coming soon")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxl)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }
}

#Preview {
    GenericDepartmentView(
        membership: EventMembershipItem(
            id: "1", eventId: "1",
            eventName: "2026 Circuit Assembly",
            eventType: "CIRCUIT_ASSEMBLY_CO",
            theme: nil,
            venue: "Assembly Hall", address: "123 Main St",
            startDate: Date(), endDate: Date().addingTimeInterval(86400 * 2),
            volunteerCount: 45, membershipType: .overseer,
            overseerRole: "DEPARTMENT_OVERSEER",
            departmentId: "d1", departmentName: "Parking",
            departmentType: "PARKING",
            departmentAccessCode: "PKG456",
            eventVolunteerId: nil, volunteerId: nil
        )
    )
    .environmentObject(AppState.shared)
}
