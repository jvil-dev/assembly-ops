//
//  VolunteerCredentialsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/28/26.
//
//  Displays volunteer credentials after adding to event.
//  Shows volunteer ID, token (masked), copy buttons, and invite message.
//
//  Components:
//    - Volunteer name header
//    - Credential cards with copy buttons
//    - Show/hide token toggle
//    - Share invite button
//
//  Design: Uses AppTheme for consistent styling
//

import SwiftUI

struct VolunteerCredentialsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    let volunteerName: String
    let volunteerId: String
    let token: String
    let inviteMessage: String

    @State private var showToken = false
    @State private var copiedId = false
    @State private var copiedToken = false
    @State private var showShareSheet = false
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Success header
                    successHeader
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Credentials card
                    credentialsCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // Invite message card
                    inviteCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

                    // Action buttons
                    actionButtons
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("Volunteer Added")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [inviteMessage])
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Success Header

    private var successHeader: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Text("\(volunteerName) has been added!")
                .font(AppTheme.Typography.title)
                .multilineTextAlignment(.center)

            Text("Share the credentials below so they can log in")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Credentials Card

    private var credentialsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("Login Credentials")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Volunteer ID
            credentialRow(
                label: "Volunteer ID",
                value: volunteerId,
                isCopied: copiedId
            ) {
                copyToClipboard(volunteerId)
                copiedId = true
                HapticManager.shared.success()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    copiedId = false
                }
            }

            Divider()

            // Token
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Token")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                    Text(showToken ? token : String(repeating: "\u{2022}", count: 12))
                        .font(.system(size: 17, design: .monospaced))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                }

                Spacer()

                // Show/Hide toggle
                Button {
                    showToken.toggle()
                    HapticManager.shared.lightTap()
                } label: {
                    Image(systemName: showToken ? "eye.slash" : "eye")
                        .foregroundStyle(AppTheme.themeColor)
                }
                .padding(.trailing, 8)

                // Copy button
                Button {
                    copyToClipboard(token)
                    copiedToken = true
                    HapticManager.shared.success()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copiedToken = false
                    }
                } label: {
                    Image(systemName: copiedToken ? "checkmark" : "doc.on.doc")
                        .foregroundStyle(copiedToken ? .green : AppTheme.themeColor)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Invite Card

    private var inviteCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "envelope.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("Invite Message")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text(inviteMessage)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .padding()
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .cornerRadius(AppTheme.CornerRadius.small)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            // Share button
            Button {
                showShareSheet = true
                HapticManager.shared.lightTap()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Invite")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.themeColor)
                .foregroundStyle(.white)
                .cornerRadius(AppTheme.CornerRadius.button)
            }

            // Copy all button
            Button {
                copyToClipboard(inviteMessage)
                HapticManager.shared.success()
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy Message")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .foregroundStyle(AppTheme.themeColor)
                .cornerRadius(AppTheme.CornerRadius.button)
            }
        }
    }

    // MARK: - Helpers

    private func credentialRow(
        label: String,
        value: String,
        isCopied: Bool,
        onCopy: @escaping () -> Void
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                Text(value)
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
            }

            Spacer()

            Button(action: onCopy) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(isCopied ? .green : AppTheme.themeColor)
            }
        }
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview("Light") {
    VolunteerCredentialsView(
        volunteerName: "John Smith",
        volunteerId: "CA-A7X9K2",
        token: "xK9mP2vL8nQ4wR6tY1zB3cD5",
        inviteMessage: """
        Hi John!

        You've been added to 2026 Circuit Assembly!

        Download the AssemblyOps app:
        [App Store Link]

        Your login credentials:
        Volunteer ID: CA-A7X9K2
        Token: xK9mP2vL8nQ4wR6tY1zB3cD5

        Questions? Contact your department overseer.
        """
    )
}

#Preview("Dark") {
    VolunteerCredentialsView(
        volunteerName: "John Smith",
        volunteerId: "RC-B3M8P1",
        token: "xK9mP2vL8nQ4wR6tY1zB3cD5",
        inviteMessage: """
        Hi John!

        You've been added to 2026 Regional Convention!

        Download the AssemblyOps app:
        [App Store Link]

        Your login credentials:
        Volunteer ID: RC-B3M8P1
        Token: xK9mP2vL8nQ4wR6tY1zB3cD5

        Questions? Contact your department overseer.
        """
    )
    .preferredColorScheme(.dark)
}
