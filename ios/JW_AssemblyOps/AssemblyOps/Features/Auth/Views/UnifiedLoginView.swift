//
//  UnifiedLoginView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/24/26.
//

// MARK: - Unified Login View
//
// Single sign-in screen for all users (overseers and volunteers).
//
// Features:
//   - Email + password login
//   - Sign in with Google / Apple
//   - Error display
//   - Link to RegistrationView

import SwiftUI
import AuthenticationServices

struct UnifiedLoginView: View {
    @StateObject private var viewModel = UnifiedLoginViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @FocusState private var focusedField: Field?
    @State private var hasAppeared = false
    @State private var showRegistration = false
    @State private var showForgotPassword = false
    @State private var showError = false

    private enum Field: Hashable {
        case email, password
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                headerSection
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                credentialsCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                oauthSection
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

                createAccountLink
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("auth.signin".localized)
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) { hasAppeared = true }
        }
        .onChange(of: viewModel.errorMessage) { _, error in
            showError = error != nil
        }
        .alert("auth.signInFailed".localized, isPresented: $showError) {
            Button("common.ok".localized) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $viewModel.showOAuthRegistration) {
            if let data = viewModel.pendingOAuthData {
                OAuthRegistrationView(
                    email: data.email,
                    firstName: data.firstName,
                    lastName: data.lastName,
                    pendingOAuthToken: data.pendingToken
                )
            }
        }
        .navigationDestination(isPresented: $showRegistration) {
            RegistrationView()
        }
        .navigationDestination(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.22 : 0.09))
                    .frame(width: 88, height: 88)

                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .shadow(color: AppTheme.themeColor.opacity(0.2), radius: 10, x: 0, y: 3)
            }

            Text("auth.welcomeBack".localized)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.themeColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppTheme.Spacing.m)
    }

    // MARK: - Email/Password Card

    private var credentialsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.themeColor)
                Text("auth.section.signIn".localized)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            VStack(spacing: AppTheme.Spacing.l) {
                UnderlineTextField(
                    label: "auth.field.email".localized,
                    placeholder: "auth.placeholder.email".localized,
                    text: $viewModel.email,
                    isSecure: false,
                    isFocused: focusedField == .email,
                    onSubmit: { focusedField = .password },
                    autocapitalization: .never,
                    keyboardType: .emailAddress,
                    isMonospaced: false
                )
                .focused($focusedField, equals: .email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                UnderlineTextField(
                    label: "auth.field.password".localized,
                    placeholder: "auth.placeholder.password".localized,
                    text: $viewModel.password,
                    isSecure: true,
                    isFocused: focusedField == .password,
                    onSubmit: { viewModel.login() },
                    autocapitalization: .never,
                    keyboardType: .default,
                    isMonospaced: false
                )
                .focused($focusedField, equals: .password)
            }

            HStack {
                Spacer()
                Button {
                    showForgotPassword = true
                } label: {
                    Text("auth.forgotPassword".localized)
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.themeColor)
                }
            }

            Button {
                focusedField = nil
                viewModel.login()
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("auth.signin".localized)
                            .font(AppTheme.Typography.bodyMedium)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.ButtonHeight.large)
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .fill(viewModel.isFormValid
                          ? AppTheme.themeColor
                          : AppTheme.themeColor.opacity(0.4))
                    .shadow(color: AppTheme.themeColor.opacity(viewModel.isFormValid ? 0.3 : 0),
                            radius: 10, x: 0, y: 3)
            )
            .foregroundStyle(.white)
            .disabled(!viewModel.isFormValid || viewModel.isLoading)
            .animation(AppTheme.quickAnimation, value: viewModel.isFormValid)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - OAuth

    private var oauthSection: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            HStack {
                Rectangle()
                    .fill(AppTheme.dividerColor(for: colorScheme))
                    .frame(height: 1)
                Text("auth.orContinueWith".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    .fixedSize()
                Rectangle()
                    .fill(AppTheme.dividerColor(for: colorScheme))
                    .frame(height: 1)
            }

            HStack(spacing: AppTheme.Spacing.m) {
                Button {
                    viewModel.signInWithGoogle()
                } label: {
                    HStack(spacing: AppTheme.Spacing.s) {
                        Text("G")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(AppTheme.googleBlue)
                        Text("Google")
                            .font(AppTheme.Typography.body)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.ButtonHeight.medium)
                }
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                        .stroke(AppTheme.dividerColor(for: colorScheme), lineWidth: 1.5)
                )
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .accessibilityLabel("auth.a11y.signInGoogle".localized)

                Button {
                    viewModel.signInWithApple()
                } label: {
                    HStack(spacing: AppTheme.Spacing.s) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 17))
                        Text("Apple")
                            .font(AppTheme.Typography.body)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.ButtonHeight.medium)
                }
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                        .stroke(AppTheme.dividerColor(for: colorScheme), lineWidth: 1.5)
                )
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .accessibilityLabel("auth.a11y.signInApple".localized)
            }
        }
    }

    // MARK: - Create Account Link

    private var createAccountLink: some View {
        HStack(spacing: 4) {
            Text("auth.dontHaveAccount".localized)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            Button {
                showRegistration = true
            } label: {
                Text("auth.createAccount".localized)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.themeColor)
            }
        }
        .padding(.top, AppTheme.Spacing.xs)
    }

}

#Preview {
    NavigationStack {
        UnifiedLoginView()
    }
}
