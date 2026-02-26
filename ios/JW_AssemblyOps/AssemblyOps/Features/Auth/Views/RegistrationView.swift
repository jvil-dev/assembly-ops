//
//  RegistrationView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/24/26.
//

// MARK: - Registration View
//
// Unified account creation for all users (overseers and volunteers).
// Replaces OverseerRegistrationView.
//
// Fields:
//   - First/Last Name (required)
//   - Email, Password, Confirm Password (required)
//   - Phone, Congregation (optional)
//   - Appointment Status picker (optional)
//   - "I am serving as a Department Overseer" toggle
//
// Features:
//   - Password match indicator
//   - Google/Apple sign-up
//   - Overseer toggle with explainer

import SwiftUI
import AuthenticationServices

struct RegistrationView: View {
    @StateObject private var viewModel = RegistrationViewModel()
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var focusedField: Field?
    @State private var hasAppeared = false
    @State private var showError = false

    private enum Field: Hashable {
        case firstName, lastName, email, password, confirmPassword, phone, congregation
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                nameCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                credentialsCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                optionalCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

                overseerCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)

                oauthSection
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.2)

                registerButton
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.25)

                termsCaption
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.3)
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) { hasAppeared = true }
        }
        .onChange(of: viewModel.errorMessage) { _, error in
            showError = error != nil
        }
        .alert("Registration Failed", isPresented: $showError) {
            Button("OK") { viewModel.errorMessage = nil }
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
    }

    // MARK: - Name Card

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
            HStack(spacing: 8) {
                Image(systemName: "person.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.themeColor)
                Text("YOUR NAME")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            HStack(spacing: AppTheme.Spacing.l) {
                UnderlineTextField(
                    label: "FIRST NAME",
                    placeholder: "First",
                    text: $viewModel.firstName,
                    isSecure: false,
                    isFocused: focusedField == .firstName,
                    onSubmit: { focusedField = .lastName },
                    autocapitalization: .words,
                    keyboardType: .default,
                    isMonospaced: false
                )
                .focused($focusedField, equals: .firstName)

                UnderlineTextField(
                    label: "LAST NAME",
                    placeholder: "Last",
                    text: $viewModel.lastName,
                    isSecure: false,
                    isFocused: focusedField == .lastName,
                    onSubmit: { focusedField = .email },
                    autocapitalization: .words,
                    keyboardType: .default,
                    isMonospaced: false
                )
                .focused($focusedField, equals: .lastName)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Credentials Card

    private var credentialsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.themeColor)
                Text("ACCOUNT CREDENTIALS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            UnderlineTextField(
                label: "EMAIL",
                placeholder: "your@email.com",
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
                label: "PASSWORD",
                placeholder: "At least 8 characters",
                text: $viewModel.password,
                isSecure: true,
                isFocused: focusedField == .password,
                onSubmit: { focusedField = .confirmPassword },
                autocapitalization: .never,
                keyboardType: .default,
                isMonospaced: false
            )
            .focused($focusedField, equals: .password)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                UnderlineTextField(
                    label: "CONFIRM PASSWORD",
                    placeholder: "Re-enter password",
                    text: $viewModel.confirmPassword,
                    isSecure: true,
                    isFocused: focusedField == .confirmPassword,
                    onSubmit: { focusedField = .phone },
                    autocapitalization: .never,
                    keyboardType: .default,
                    isMonospaced: false
                )
                .focused($focusedField, equals: .confirmPassword)

                if !viewModel.confirmPassword.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.caption)
                        Text(viewModel.passwordsMatch ? "Passwords match" : "Passwords don't match")
                            .font(.caption)
                    }
                    .foregroundStyle(viewModel.passwordsMatch
                        ? AppTheme.StatusColors.accepted
                        : AppTheme.StatusColors.declined)
                    .transition(.opacity)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Optional Fields Card

    private var optionalCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.themeColor)
                Text("OPTIONAL INFO")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            UnderlineTextField(
                label: "PHONE",
                placeholder: "Your phone number",
                text: $viewModel.phone,
                isSecure: false,
                isFocused: focusedField == .phone,
                onSubmit: { focusedField = .congregation },
                autocapitalization: .never,
                keyboardType: .phonePad,
                isMonospaced: false
            )
            .focused($focusedField, equals: .phone)

            UnderlineTextField(
                label: "CONGREGATION",
                placeholder: "Your congregation name",
                text: $viewModel.congregation,
                isSecure: false,
                isFocused: focusedField == .congregation,
                onSubmit: { focusedField = nil },
                autocapitalization: .words,
                keyboardType: .default,
                isMonospaced: false
            )
            .focused($focusedField, equals: .congregation)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                Text("APPOINTMENT STATUS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

                Picker("Appointment Status", selection: $viewModel.appointmentStatus) {
                    Text("None").tag(String?.none)
                    Text("Publisher").tag(String?.some("PUBLISHER"))
                    Text("Ministerial Servant").tag(String?.some("MINISTERIAL_SERVANT"))
                    Text("Elder").tag(String?.some("ELDER"))
                }
                .pickerStyle(.menu)
                .tint(AppTheme.themeColor)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Overseer Toggle Card

    private var overseerCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            Toggle(isOn: $viewModel.isOverseer) {
                HStack(spacing: AppTheme.Spacing.m) {
                    Image(systemName: "shield.fill")
                        .foregroundStyle(AppTheme.themeColor)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("auth.isOverseer.toggle", comment: ""))
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        if viewModel.isOverseer {
                            Text(NSLocalizedString("auth.isOverseer.explainer", comment: ""))
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.themeColor)
                                .transition(.opacity)
                        }
                    }
                }
            }
            .tint(AppTheme.themeColor)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isOverseer)
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
                Text("or sign up with")
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
                            .foregroundStyle(Color(red: 0.26, green: 0.52, blue: 0.96))
                        Text("Google").font(AppTheme.Typography.body)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.ButtonHeight.medium)
                }
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                        .stroke(AppTheme.dividerColor(for: colorScheme), lineWidth: 1.5)
                )
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                Button {
                    viewModel.signInWithApple()
                } label: {
                    HStack(spacing: AppTheme.Spacing.s) {
                        Image(systemName: "apple.logo").font(.system(size: 17))
                        Text("Apple").font(AppTheme.Typography.body)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.ButtonHeight.medium)
                }
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                        .stroke(AppTheme.dividerColor(for: colorScheme), lineWidth: 1.5)
                )
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
    }

    // MARK: - Register Button

    private var registerButton: some View {
        Button {
            focusedField = nil
            viewModel.register()
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Create Account")
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

    // MARK: - Terms

    private var termsCaption: some View {
        Text("By creating an account, you agree to our Terms of Service")
            .font(.footnote)
            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            .multilineTextAlignment(.center)
            .padding(.bottom, AppTheme.Spacing.s)
    }
}

#Preview {
    NavigationStack {
        RegistrationView()
    }
}
