//
//  ProfileSetupView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/31/26.
//

// MARK: - Overseer Profile Setup View
//
// Mandatory full-screen profile completion for new overseers.
// Blocks access to dashboard until congregation is selected.
// Cannot be dismissed - user must complete the form to proceed.
//
// Sections:
//   1. Welcome header
//   2. Name fields (pre-filled from login)
//   3. Phone (optional)
//   4. Circuit picker -> filters congregations
//   5. Congregation picker (filtered by circuit)
//   6. Circuit info card (read-only, auto-filled)
//   7. Continue button
//

import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ProfileSetupViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Welcome header
                    welcomeHeader
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Name fields
                    nameCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // Congregation search
                    congregationCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    // Continue button
                    continueButton
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.2)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("Profile Setup")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.prefill()
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.themeColor)

            Text("Complete Your Profile")
                .font(AppTheme.Typography.title)
                .fontWeight(.bold)

            Text("Tell us about yourself so we can connect you with your congregation and circuit.")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, AppTheme.Spacing.l)
    }

    // MARK: - Name Card

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "person.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("Personal Information")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            VStack(spacing: AppTheme.Spacing.m) {
                profileTextField("First Name", text: $viewModel.firstName)
                profileTextField("Last Name", text: $viewModel.lastName)
                profileTextField("Phone (optional)", text: $viewModel.phone)
                    .keyboardType(.phonePad)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Congregation Card

    private var congregationCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "building.2.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("Congregation")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            CongregationSearchField(
                selectedName: $viewModel.congregationName,
                selectedId: $viewModel.congregationId
            )
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            viewModel.saveProfile()
        } label: {
            HStack(spacing: AppTheme.Spacing.s) {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Continue")
                        .font(AppTheme.Typography.headline)
                    Image(systemName: "arrow.right")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.l)
            .background(viewModel.isFormValid ? AppTheme.themeColor : AppTheme.themeColor.opacity(0.4))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
        }
        .disabled(!viewModel.isFormValid || viewModel.isSaving)
    }

    // MARK: - Helpers

    private func profileTextField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            TextField("", text: text)
                .font(AppTheme.Typography.body)
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
    }

}

#Preview("Light") {
    ProfileSetupView()
        .environmentObject(AppState.shared)
}

#Preview("Dark") {
    ProfileSetupView()
        .environmentObject(AppState.shared)
        .preferredColorScheme(.dark)
}
