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
//   - Language: Segmented picker (English / Español)
//   - Logout: Destructive button with confirmation alert
//
// Navigation:
//   - Presented as .sheet from EventsHomeView
//   - "Done" button dismisses
//   - Edit Profile opens EditOverseerProfileSheet as nested sheet
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var showLogoutConfirmation = false
    @State private var showEditProfile = false
    @State private var hasAppeared = false
    @State private var copiedId = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Profile header
                    profileHeader
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Language selector
                    languageCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // Logout button
                    logoutButton
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

                    // App version
                    appVersion
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
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
                EditOverseerProfileSheet()
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

    // MARK: - Language Card

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "globe")
                    .foregroundStyle(AppTheme.themeColor)
                Text("LANGUAGE")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Picker("language.select".localized, selection: $localizationManager.currentLanguage) {
                Text("language.english".localized).tag("en")
                Text("language.spanish".localized).tag("es")
            }
            .pickerStyle(.segmented)
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
