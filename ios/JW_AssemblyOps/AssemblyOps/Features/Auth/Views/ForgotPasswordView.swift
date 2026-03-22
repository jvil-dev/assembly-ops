//
//  ForgotPasswordView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/19/26.
//

// MARK: - Forgot Password View
//
// Single view that switches on viewModel.step to show:
//   - Step 1: Email field + "Send Code" button
//   - Step 2: 6-digit code entry + "Verify" + "Resend Code"
//   - Step 3: New password + confirm + password requirements + "Reset Password"
//
// On successful reset: calls AppState.didLogin() (auto-login), then dismisses.
// Navigated to from UnifiedLoginView via "Forgot Password?" link.

import SwiftUI

struct ForgotPasswordView: View {
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @FocusState private var focusedField: Field?
    @State private var hasAppeared = false
    @State private var showError = false

    private enum Field: Hashable {
        case email, code, newPassword, confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                headerSection
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                switch viewModel.step {
                case .enterEmail:
                    emailCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                case .enterCode:
                    codeCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                case .newPassword:
                    passwordCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("auth.forgotPassword.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) { hasAppeared = true }
        }
        .onChange(of: viewModel.errorMessage) { _, error in
            showError = error != nil
        }
        .onChange(of: viewModel.didResetSuccessfully) { _, success in
            if success { dismiss() }
        }
        .alert("auth.forgotPassword.title".localized, isPresented: $showError) {
            Button("common.ok".localized) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .animation(AppTheme.quickAnimation, value: viewModel.step)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.22 : 0.09))
                    .frame(width: 88, height: 88)

                Image(systemName: "key.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.themeColor)
            }

            Text("auth.forgotPassword.title".localized)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.themeColor)

            Text(stepDescription)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppTheme.Spacing.m)
    }

    private var stepDescription: String {
        switch viewModel.step {
        case .enterEmail:
            return NSLocalizedString("auth.forgotPassword.enterEmail", comment: "")
        case .enterCode:
            return NSLocalizedString("auth.forgotPassword.enterCode", comment: "")
        case .newPassword:
            return NSLocalizedString("auth.forgotPassword.newPassword", comment: "")
        }
    }

    // MARK: - Step 1: Email Card

    private var emailCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.themeColor)
                Text("auth.field.email".localized)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            UnderlineTextField(
                label: "auth.field.email".localized,
                placeholder: "auth.placeholder.email".localized,
                text: $viewModel.email,
                isSecure: false,
                isFocused: focusedField == .email,
                onSubmit: { viewModel.requestReset() },
                autocapitalization: .never,
                keyboardType: .emailAddress,
                isMonospaced: false
            )
            .focused($focusedField, equals: .email)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            actionButton(
                title: "auth.forgotPassword.sendCode".localized,
                enabled: viewModel.canSendCode,
                action: {
                    focusedField = nil
                    viewModel.requestReset()
                }
            )
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Step 2: Code Card

    private var codeCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
            UnderlineTextField(
                label: "",
                placeholder: "000000",
                text: $viewModel.code,
                isSecure: false,
                isFocused: focusedField == .code,
                onSubmit: { viewModel.verifyCode() },
                autocapitalization: .never,
                keyboardType: .numberPad,
                isMonospaced: true
            )
            .focused($focusedField, equals: .code)

            Text("auth.forgotPassword.codeExpiry".localized)
                .font(AppTheme.Typography.captionSmall)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            actionButton(
                title: "auth.forgotPassword.verify".localized,
                enabled: viewModel.canVerifyCode,
                action: {
                    focusedField = nil
                    viewModel.verifyCode()
                }
            )

            HStack {
                Spacer()
                Button {
                    viewModel.resendCode()
                } label: {
                    Group {
                        if viewModel.resendCooldown > 0 {
                            Text(String(
                                format: NSLocalizedString("auth.forgotPassword.resendCountdown", comment: ""),
                                viewModel.resendCooldown
                            ))
                        } else {
                            Text("auth.forgotPassword.resend".localized)
                        }
                    }
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.resendCooldown > 0
                        ? AppTheme.themeColor.opacity(0.4)
                        : AppTheme.themeColor)
                }
                .disabled(viewModel.isLoading || viewModel.resendCooldown > 0)
                Spacer()
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Step 3: Password Card

    private var passwordCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.themeColor)
                Text("auth.forgotPassword.newPassword".localized)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            UnderlineTextField(
                label: NSLocalizedString("auth.forgotPassword.newPassword", comment: ""),
                placeholder: "••••••••",
                text: $viewModel.newPassword,
                isSecure: true,
                isFocused: focusedField == .newPassword,
                onSubmit: { focusedField = .confirmPassword },
                autocapitalization: .never,
                keyboardType: .default,
                isMonospaced: false,
                textContentType: .newPassword
            )
            .focused($focusedField, equals: .newPassword)

            UnderlineTextField(
                label: NSLocalizedString("auth.field.confirmPassword", comment: ""),
                placeholder: "••••••••",
                text: $viewModel.confirmNewPassword,
                isSecure: true,
                isFocused: focusedField == .confirmPassword,
                onSubmit: { viewModel.resetPassword() },
                autocapitalization: .never,
                keyboardType: .default,
                isMonospaced: false,
                textContentType: .newPassword
            )
            .focused($focusedField, equals: .confirmPassword)

            // Password requirements hint
            VStack(alignment: .leading, spacing: 4) {
                requirementRow(met: viewModel.newPassword.count >= 8, text: "8+ characters")
                requirementRow(met: viewModel.newPassword.range(of: "[A-Z]", options: .regularExpression) != nil, text: "One uppercase letter")
                requirementRow(met: viewModel.newPassword.range(of: "[a-z]", options: .regularExpression) != nil, text: "One lowercase letter")
                requirementRow(met: viewModel.newPassword.range(of: "[0-9]", options: .regularExpression) != nil, text: "One number")
            }
            .padding(.top, -AppTheme.Spacing.s)

            if !viewModel.passwordsMatch {
                Text("auth.passwordsDoNotMatch".localized)
                    .font(AppTheme.Typography.captionSmall)
                    .foregroundStyle(AppTheme.StatusColors.declined)
            }

            actionButton(
                title: "auth.forgotPassword.reset".localized,
                enabled: viewModel.canResetPassword,
                action: {
                    focusedField = nil
                    viewModel.resetPassword()
                }
            )
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Helpers

    private func actionButton(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if viewModel.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(AppTheme.Typography.bodyMedium)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.ButtonHeight.large)
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                .fill(enabled ? AppTheme.themeColor : AppTheme.themeColor.opacity(0.4))
                .shadow(color: AppTheme.themeColor.opacity(enabled ? 0.3 : 0),
                        radius: 10, x: 0, y: 3)
        )
        .foregroundStyle(.white)
        .disabled(!enabled || viewModel.isLoading)
        .animation(AppTheme.quickAnimation, value: enabled)
    }

    private func requirementRow(met: Bool, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12))
                .foregroundStyle(met ? AppTheme.StatusColors.accepted : AppTheme.textTertiary(for: colorScheme))
            Text(text)
                .font(AppTheme.Typography.captionSmall)
                .foregroundStyle(met ? AppTheme.textSecondary(for: colorScheme) : AppTheme.textTertiary(for: colorScheme))
        }
    }
}
