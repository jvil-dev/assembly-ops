//
//  SettingsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/25/26.
//

// MARK: - Settings View
//
// Global settings sheet presented from EventsHomeView's profile avatar.
// Accessible to all users (overseers and volunteers).
//
// Sections:
//   - Profile header: Avatar with initials, name, email, userId badge, edit button
//   - Language: NavigationLink to LanguageSettingsView
//   - Archived Events: NavigationLink to ArchivedEventsView
//   - Logout: Destructive button with confirmation alert
//
// Navigation:
//   - Presented as .sheet from EventsHomeView
//   - "Done" button dismisses
//   - Edit Profile opens EditProfileSheet as nested sheet
//

import SwiftUI
import Apollo

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var showLogoutConfirmation = false
    @State private var showEditProfile = false
    @State private var hasAppeared = false
    @State private var copiedId = false
    @State private var isSavingOverseerMode = false
    @State private var showOverseerError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Profile header
                    profileHeader
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Language nav row
                    languageRow
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // Archived Events nav row
                    archivedEventsRow
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

                    // Overseer mode toggle
                    overseerModeRow
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)

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
            .navigationTitle("settings.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done".localized) { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet()
                    .environmentObject(appState)
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
            .alert("profile.logout".localized, isPresented: $showLogoutConfirmation) {
                Button("common.cancel".localized, role: .cancel) {}
                Button("profile.logout".localized, role: .destructive) {
                    appState.logout()
                    dismiss()
                }
            } message: {
                Text("settings.logout.confirm".localized)
            }
            .alert("common.error".localized, isPresented: $showOverseerError) {
                Button("common.ok".localized, role: .cancel) {}
            } message: {
                Text("settings.overseerMode.error".localized)
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        Button {
            showEditProfile = true
            HapticManager.shared.lightTap()
        } label: {
            VStack(spacing: AppTheme.Spacing.l) {
                if let user = appState.currentUser {
                    ZStack(alignment: .bottomTrailing) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.themeColor.opacity(0.15))
                                .frame(width: 88, height: 88)

                            Circle()
                                .strokeBorder(AppTheme.themeColor.opacity(0.3), lineWidth: 2)
                                .frame(width: 88, height: 88)

                            Text(user.initials)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.themeColor)
                        }

                        // Edit badge
                        Circle()
                            .fill(AppTheme.themeColor)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "pencil")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white)
                            )
                            .offset(x: 2, y: 2)
                    }

                    VStack(spacing: AppTheme.Spacing.xs) {
                        Text(user.fullName)
                            .font(AppTheme.Typography.title)
                            .foregroundStyle(.primary)

                        Text(user.email)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                        // User ID badge
                        Button {
                            UIPasteboard.general.string = user.userId
                            HapticManager.shared.success()
                            copiedId = true
                            Task { try? await Task.sleep(for: .seconds(2)); copiedId = false }
                        } label: {
                            HStack(spacing: AppTheme.Spacing.xs) {
                                Text("YOUR ID")
                                    .font(AppTheme.Typography.captionSmall)
                                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                                Text(user.userId)
                                    .font(.system(.body, design: .monospaced).weight(.semibold))
                                    .foregroundStyle(AppTheme.themeColor)
                                Image(systemName: copiedId ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            }
                            .padding(.horizontal, AppTheme.Spacing.m)
                            .padding(.vertical, AppTheme.Spacing.s)
                            .background(AppTheme.themeColor.opacity(0.08))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .cardPadding()
            .padding(.vertical, AppTheme.Spacing.s)
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Language Row

    private var languageRow: some View {
        NavigationLink {
            LanguageSettingsView()
        } label: {
            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "globe")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.themeColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("settings.language".localized)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(.primary)
                    Text(localizationManager.currentLanguage == "es" ? "Español" : "English")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Archived Events Row

    private var archivedEventsRow: some View {
        NavigationLink {
            ArchivedEventsView()
        } label: {
            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "archivebox")
                        .font(.system(size: 16))
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("settings.archivedEvents".localized)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(.primary)
                    Text("settings.archivedEvents.subtitle".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Overseer Mode Row

    private var overseerModeRow: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "building.2")
                    .font(.system(size: 16))
                    .foregroundStyle(.purple)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("profile.overseerMode".localized)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundStyle(.primary)
                Text("profile.overseerMode.subtitle".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            Spacer()

            if isSavingOverseerMode {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Toggle("", isOn: Binding(
                    get: { appState.isOverseer },
                    set: { newValue in setOverseerMode(newValue) }
                ))
                .labelsHidden()
                .tint(AppTheme.themeColor)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Logout Button

    private var logoutButton: some View {
        Button {
            showLogoutConfirmation = true
        } label: {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("profile.logout".localized)
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

    // MARK: - Overseer Mode Mutation

    private func setOverseerMode(_ newValue: Bool) {
        isSavingOverseerMode = true
        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.SetOverseerModeMutation(isOverseer: newValue)
        ) { result in
            Task { @MainActor in
                self.isSavingOverseerMode = false
                if case .success(let r) = result, r.data?.setOverseerMode != nil {
                    self.appState.didUpdateOverseerMode(isOverseer: newValue)
                    HapticManager.shared.success()
                } else {
                    self.appState.didUpdateOverseerMode(isOverseer: !newValue)
                    self.showOverseerError = true
                    HapticManager.shared.error()
                }
            }
        }
    }

    // MARK: - App Version

    private var appVersion: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
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
}

#Preview {
    SettingsView()
        .environmentObject(AppState.shared)
}
