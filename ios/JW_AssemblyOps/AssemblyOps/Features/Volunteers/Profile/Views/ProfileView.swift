//
//  ProfileView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/3/26.
//

// MARK: - Profile View
//
// Displays volunteer profile information and provides logout functionality.
// Uses the app's design system with warm background and floating cards.
//
// Components:
//   - Profile header: Avatar with initials, name, congregation, appointment status
//   - Department card: Department name with lanyard color indicator
//   - Event card: Event name, venue, address, dates
//   - Contact card: Phone and email (if available)
//   - Logout button: Confirms and logs out volunteer
//
// Features:
//   - Warm gradient background
//   - Floating cards with layered shadows
//   - Staggered entrance animations
//   - Pull to refresh
//
// Dependencies:
//   - ProfileViewModel: Fetches volunteer data from GraphQL
//   - AppState: Handles logout
//   - DepartmentColor: Provides department color mapping
//   - AppTheme: Design system tokens
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme

    @State private var showingLogoutAlert = false
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.hasLoaded {
                    LoadingView(message: "Loading profile...")
                } else if let error = viewModel.errorMessage, viewModel.volunteer == nil {
                    ErrorView(message: error) {
                        viewModel.refresh()
                    }
                } else if let volunteer = viewModel.volunteer {
                    profileContent(volunteer: volunteer)
                } else {
                    EmptyView()
                }
            }
            .navigationTitle("Profile")
            .refreshable {
                viewModel.refresh()
            }
            .task {
                if !viewModel.hasLoaded {
                    viewModel.fetchProfile()
                }
            }
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    Task {
                        appState.logout()
                    }
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }

    private func profileContent(volunteer: Volunteer) -> some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Profile header
                profileHeader(volunteer: volunteer)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                // Department card
                if let deptName = volunteer.departmentName,
                   let deptType = volunteer.departmentType {
                    departmentCard(name: deptName, type: deptType)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                }

                // Event info
                eventCard(volunteer: volunteer)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

                // Contact info
                if volunteer.phone != nil || volunteer.email != nil {
                    contactCard(volunteer: volunteer)
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
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Profile Header

    private func profileHeader(volunteer: Volunteer) -> some View {
        VStack(spacing: AppTheme.Spacing.l) {
            // Avatar with initials
            ZStack {
                Circle()
                    .fill(volunteer.departmentColor.opacity(0.15))
                    .frame(width: 88, height: 88)

                Circle()
                    .strokeBorder(volunteer.departmentColor.opacity(0.3), lineWidth: 2)
                    .frame(width: 88, height: 88)

                Text(volunteer.initials)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(volunteer.departmentColor)
            }

            VStack(spacing: AppTheme.Spacing.xs) {
                Text(volunteer.fullName)
                    .font(AppTheme.Typography.title)
                    .foregroundStyle(.primary)

                Text(volunteer.congregation)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                if let appointment = volunteer.appointmentStatus {
                    Text(formatAppointment(appointment))
                        .font(AppTheme.Typography.captionBold)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .cardPadding()
        .padding(.vertical, AppTheme.Spacing.s)
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Department Card

    private func departmentCard(name: String, type: String) -> some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Department icon circle
            Circle()
                .fill(DepartmentColor.color(for: type))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: departmentIcon(for: type))
                        .foregroundStyle(.white)
                        .font(.system(size: 18, weight: .medium))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Department")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                Text(name)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
            }

            Spacer()

            // Lanyard color indicator
            VStack(spacing: 2) {
                Text(DepartmentColor.colorName(for: type))
                    .font(AppTheme.Typography.captionSmall)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                Text("Lanyard")
                    .font(AppTheme.Typography.captionSmall)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Event Card

    private func eventCard(volunteer: Volunteer) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(AppTheme.themeColor)
                Text("Event")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text(volunteer.eventName)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                if let venue = volunteer.eventVenue {
                    infoRow(icon: "building.2", text: venue)
                }

                if let address = volunteer.eventAddress {
                    infoRow(icon: "location", text: address)
                }

                if let dateRange = volunteer.eventDateRange {
                    infoRow(icon: "clock", text: dateRange)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Contact Card

    private func contactCard(volunteer: Volunteer) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "person.text.rectangle")
                    .foregroundStyle(AppTheme.themeColor)
                Text("Contact Info")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                if let phone = volunteer.phone {
                    infoRow(icon: "phone", text: phone)
                }

                if let email = volunteer.email {
                    infoRow(icon: "envelope", text: email)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        Button(role: .destructive) {
            showingLogoutAlert = true
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

    private func formatAppointment(_ status: String) -> String {
        switch status.uppercased() {
        case "ELDER": return "Elder"
        case "MINISTERIAL_SERVANT": return "Ministerial Servant"
        case "PUBLISHER": return "Publisher"
        default: return status
        }
    }

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
    ProfileView()
        .environmentObject(AppState.shared)
}

#Preview("Dark Mode") {
    ProfileView()
        .environmentObject(AppState.shared)
        .preferredColorScheme(.dark)
}
