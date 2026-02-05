//
//  OverseerProfileView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Overseer Profile View
//
// Profile and settings screen for overseer users.
// Uses the app's design system with warm background and floating cards.
//
// Sections:
//   - Profile header: Avatar with initials, name, email, role badge
//   - Current Event: Active event name and venue
//   - Department: Current department with color indicator (if selected)
//   - Logout: Styled button with confirmation dialog
//
// Features:
//   - Warm gradient background
//   - Floating cards with layered shadows
//   - Staggered entrance animations
//   - Reads overseer info from AppState.currentOverseer
//   - Reads event/department context from OverseerSessionState
//

import SwiftUI

struct OverseerProfileView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var sessionState = OverseerSessionState.shared
    @Environment(\.colorScheme) var colorScheme

    @State private var showLogoutConfirmation = false
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Profile header
                    profileHeader
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Current event card
                    if sessionState.selectedEvent != nil {
                        eventCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                    }

                    // Department card
                    if sessionState.selectedDepartment != nil {
                        departmentCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                    }

                    // Admin management (App Admins only)
                    if sessionState.isEventOverseer {
                        adminManagementLink
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
                    }

                    // Logout button
                    logoutButton
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.2)

                    // App version
                    appVersion
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.25)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("Profile")
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
            .confirmationDialog(
                "Are you sure you want to log out?",
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Log Out", role: .destructive) {
                    appState.logout()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            // Avatar with initials
            if let overseer = appState.currentOverseer {
                ZStack {
                    Circle()
                        .fill(AppTheme.themeColor.opacity(0.15))
                        .frame(width: 88, height: 88)

                    Circle()
                        .strokeBorder(AppTheme.themeColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 88, height: 88)

                    Text(overseer.initials)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.themeColor)
                }

                VStack(spacing: AppTheme.Spacing.xs) {
                    Text(overseer.fullName)
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(.primary)

                    Text(overseer.email)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                    // Role badge
                    Text(sessionState.isEventOverseer
                        ? NSLocalizedString("role.app_admin", comment: "")
                        : NSLocalizedString("role.department_overseer", comment: ""))
                        .font(AppTheme.Typography.captionBold)
                        .foregroundStyle(AppTheme.themeColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.themeColor.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .cardPadding()
        .padding(.vertical, AppTheme.Spacing.s)
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Event Card

    private var eventCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(AppTheme.themeColor)
                Text("Current Event")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            if let event = sessionState.selectedEvent {
                Text(event.name)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)

                infoRow(icon: "building.2", text: event.venue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Department Card

    private var departmentCard: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            if let department = sessionState.selectedDepartment {
                // Department icon circle
                Circle()
                    .fill(DepartmentColor.color(for: department.departmentType))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: departmentIcon(for: department.departmentType))
                            .foregroundStyle(.white)
                            .font(.system(size: 18, weight: .medium))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Department")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text(department.name)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                }

                Spacer()

                // Lanyard color indicator
                VStack(spacing: 2) {
                    Text(DepartmentColor.colorName(for: department.departmentType))
                        .font(AppTheme.Typography.captionSmall)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Text("Lanyard")
                        .font(AppTheme.Typography.captionSmall)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Admin Management Link

    private var adminManagementLink: some View {
        NavigationLink(destination: AdminManagementView()) {
            HStack {
                Image(systemName: "person.2.badge.gearshape")
                    .foregroundStyle(AppTheme.themeColor)
                    .frame(width: 24)
                Text(NSLocalizedString("admin.manage.title", comment: ""))
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
        }
        .buttonStyle(.plain)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Info Row Helper

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                .frame(width: 16)
            Text(text)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
    }

    // MARK: - Logout Button

    private var logoutButton: some View {
        Button {
            showLogoutConfirmation = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Log Out")
            }
            .font(AppTheme.Typography.headline)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.ButtonHeight.medium)
            .foregroundStyle(AppTheme.StatusColors.declined)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .fill(AppTheme.StatusColors.declinedBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .strokeBorder(AppTheme.StatusColors.declined.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - App Version

    private var appVersion: some View {
        VStack(spacing: 4) {
            Text("AssemblyOps")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text("Version \(version) (\(build))")
                    .font(AppTheme.Typography.captionSmall)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
        }
        .padding(.top, AppTheme.Spacing.s)
    }

    // MARK: - Helpers

    private func departmentIcon(for type: String) -> String {
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
        default: return "person"
        }
    }
}

#Preview {
    OverseerProfileView()
        .environmentObject(AppState.shared)
}

#Preview("Dark Mode") {
    OverseerProfileView()
        .environmentObject(AppState.shared)
        .preferredColorScheme(.dark)
}
