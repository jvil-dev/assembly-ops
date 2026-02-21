//
//  OverseerProfileSetupView.swift
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

struct OverseerProfileSetupView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = OverseerProfileSetupViewModel()
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

                    // Circuit & Congregation selection
                    congregationCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

                    // Circuit info (shown after selecting congregation)
                    if viewModel.selectedCongregation != nil, let circuit = viewModel.selectedCircuit {
                        circuitInfoCard(circuit: circuit)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
                    }

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
                viewModel.loadCircuits()
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
            HStack(spacing: 8) {
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
            HStack(spacing: 8) {
                Image(systemName: "building.2.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("Congregation")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Circuit Picker
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                Text("Circuit")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                if viewModel.isLoadingCircuits {
                    HStack {
                        ProgressView()
                        Text("Loading circuits...")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                } else {
                    Menu {
                        ForEach(viewModel.circuits) { circuit in
                            Button {
                                viewModel.loadCongregations(for: circuit)
                                HapticManager.shared.lightTap()
                            } label: {
                                Text(circuit.code)
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedCircuit?.code ?? "Select a circuit")
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(viewModel.selectedCircuit != nil
                                    ? (colorScheme == .dark ? .white : .primary)
                                    : AppTheme.textTertiary(for: colorScheme))
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }
                        .padding(AppTheme.Spacing.m)
                        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    }
                }
            }

            // Congregation Picker (shown after circuit selection)
            if viewModel.selectedCircuit != nil {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                    Text("Congregation")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                    if viewModel.isLoadingCongregations {
                        HStack {
                            ProgressView()
                            Text("Loading congregations...")
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        }
                    } else if viewModel.congregations.isEmpty {
                        Text("No congregations found for this circuit")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    } else {
                        Menu {
                            ForEach(viewModel.congregations) { cong in
                                Button {
                                    viewModel.selectedCongregation = cong
                                    HapticManager.shared.lightTap()
                                } label: {
                                    Text("\(cong.name) - \(cong.city)")
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.selectedCongregation.map { "\($0.name) - \($0.city)" } ?? "Select a congregation")
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(viewModel.selectedCongregation != nil
                                        ? (colorScheme == .dark ? .white : .primary)
                                        : AppTheme.textTertiary(for: colorScheme))
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            }
                            .padding(AppTheme.Spacing.m)
                            .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                        }
                    }
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Circuit Info Card

    private func circuitInfoCard(circuit: CircuitItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "map.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("Circuit Information")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                infoRow(label: "Circuit", value: circuit.code)
                infoRow(label: "Region", value: circuit.region)
                infoRow(label: "Language", value: circuit.language.uppercased())
            }
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

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            Spacer()
            Text(value)
                .font(AppTheme.Typography.body)
                .fontWeight(.medium)
        }
    }
}

#Preview("Light") {
    OverseerProfileSetupView()
        .environmentObject(AppState.shared)
}

#Preview("Dark") {
    OverseerProfileSetupView()
        .environmentObject(AppState.shared)
        .preferredColorScheme(.dark)
}
