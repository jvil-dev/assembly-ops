//
//  VolunteerLoginView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Login View
//
// Volunteer login screen with credential entry form.
// Volunteers receive their ID and token from their overseer.
//
// Components:
//   - Header: App logo and branding
//   - Form: Volunteer ID and Token fields with auto-capitalization
//   - Error display: Shows authentication errors
//   - Login button: Disabled until form is valid
//   - Help text: Instructions for obtaining credentials
//
// Behavior:
//   - Fields auto-capitalize and trim whitespace
//   - Keyboard navigation: ID → Token → Submit
//   - Button shows loading spinner during login
//   - On success: AppState.isLoggedIn triggers navigation to MainTabView
//
// Dependencies:
//   - LoginViewModel: Handles form state and API calls
//
// Used by: JW_AssemblyOpsApp.swift (when not logged in)

import SwiftUI

struct UnderlineTextField: View {
    @Environment(\.colorScheme) var colorScheme

    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var isFocused: Bool
    var onSubmit: () -> Void = {}

    var autocapitalization: TextInputAutocapitalization = .characters
    var keyboardType: UIKeyboardType = .default
    var isMonospaced: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Floating label
            Text(label)
                .font(AppTheme.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(isFocused ? AppTheme.themeColor : Color.gray)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            // Text field
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .submitLabel(.go)
                        .onSubmit(onSubmit)
                } else {
                    TextField(placeholder, text: $text)
                        .submitLabel(.next)
                        .onSubmit(onSubmit)
                }
            }
            .font(isMonospaced
                ? .system(size: 17, weight: .regular, design: .monospaced)
                : .system(size: 17, weight: .regular, design: .default))
            .foregroundStyle(colorScheme == .dark ? .white : .black)
            .textInputAutocapitalization(autocapitalization)
            .keyboardType(keyboardType)
            .autocorrectionDisabled()
            .tint(AppTheme.themeColor)

            // Animated underline
            Rectangle()
                .fill(isFocused ? AppTheme.themeColor.opacity(0.3) : Color.clear)
                .frame(height: isFocused ? 2 : 1)
                .animation(.easeInOut(duration: 0.25), value: isFocused)
        }
    }
}


struct VolunteerLoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = VolunteerLoginViewModel()
    @FocusState private var focusedField: Field?
    @State private var hasAppeared = false

    private enum Field {
        case volunteerId
        case token
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: geometry.size.height * 0.12)

                        cardContent
                            .padding(.horizontal, 28)

                        Spacer(minLength: geometry.size.height * 0.08)
                    }
                    .frame(minHeight: geometry.size.height)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width > 100 && abs(value.translation.height) < 100 {
                        dismiss()
                    }
                }
        )
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Card

    private var cardContent: some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            headerSection
            formSection
            errorSection
            loginButton
            helpText
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
        .padding(.vertical, 40)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .shadow(color: AppTheme.Shadow.cardPrimary.color, radius: AppTheme.Shadow.cardPrimary.radius, x: 0, y: AppTheme.Shadow.cardPrimary.y)
        .shadow(color: AppTheme.Shadow.cardSecondary.color, radius: AppTheme.Shadow.cardSecondary.radius, x: 0, y: AppTheme.Shadow.cardSecondary.y)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .shadow(color: AppTheme.themeColor.opacity(0.15), radius: 12, x: 0, y: 4)

            Text("AssemblyOps")
                .font(.system(size: 28, weight: .semibold, design: .default))
                .foregroundStyle(AppTheme.themeColor)
                .tracking(0.5)

            Text("Sign in to view your assignments")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Volunteer ID field with prefix picker
            VStack(alignment: .leading, spacing: 6) {
                Text("VOLUNTEER ID")
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(focusedField == .volunteerId ? AppTheme.themeColor : Color.gray)
                    .animation(.easeInOut(duration: 0.2), value: focusedField)

                HStack(spacing: 0) {
                    // Event type prefix picker
                    Picker("", selection: $viewModel.idPrefix) {
                        Text("CA").tag("CA")
                        Text("RC").tag("RC")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .font(.system(size: 17, weight: .medium, design: .monospaced))
                    .tint(colorScheme == .dark ? .white.opacity(0.8) : .gray)
                    .frame(width: 60)

                    // Dash separator
                    Text("-")
                        .font(.system(size: 17, weight: .medium, design: .monospaced))
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.6) : .gray)

                    // User input (suffix only)
                    TextField("XXXXXX", text: $viewModel.volunteerId)
                        .font(.system(size: 17, weight: .regular, design: .monospaced))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .tint(AppTheme.themeColor)
                        .focused($focusedField, equals: .volunteerId)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .token }
                }

                // Underline
                Rectangle()
                    .fill(focusedField == .volunteerId ? AppTheme.themeColor.opacity(0.3) : Color.clear)
                    .frame(height: focusedField == .volunteerId ? 2 : 1)
                    .animation(.easeInOut(duration: 0.25), value: focusedField)
            }

            // Token field
            UnderlineTextField(
                label: "TOKEN",
                placeholder: "Enter your token",
                text: $viewModel.token,
                isSecure: true,
                isFocused: focusedField == .token,
                onSubmit: { Task { viewModel.login() } }
            )
            .focused($focusedField, equals: .token)
        }
    }


    // MARK: - Error

    @ViewBuilder
    private var errorSection: some View {
        if let error = viewModel.errorMessage {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(AppTheme.Typography.subheadline)
                Text(error)
                    .font(AppTheme.Typography.subheadline)
            }
            .foregroundStyle(AppTheme.StatusColors.declined)
            .padding(.horizontal, AppTheme.Spacing.l)
            .padding(.vertical, AppTheme.Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.StatusColors.declinedBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    // MARK: - Button

    private var loginButton: some View {
        Button {
            Task { viewModel.login() }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Sign In")
                        .font(AppTheme.Typography.bodyMedium)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.ButtonHeight.large)
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                .fill(viewModel.isFormValid ? AppTheme.themeColor : AppTheme.themeColor.opacity(0.4))
        )
        .foregroundStyle(.white)
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isFormValid)
    }

    // MARK: - Help

    private var helpText: some View {
        Text("Need help? Ask your department overseer")
            .font(AppTheme.Typography.caption)
            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            .multilineTextAlignment(.center)
    }
}

#Preview {
    VolunteerLoginView()
}
