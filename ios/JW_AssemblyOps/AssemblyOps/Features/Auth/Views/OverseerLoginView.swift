//
//  OverseerLoginView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/17/26.
//

// MARK: - Overseer Login View
//
// Login screen for overseer authentication with email/password and OAuth options.
// Presented as a full-screen view from LandingView.
//
// Features:
//   - Email/password form with validation
//   - Sign in with Apple button
//   - Sign in with Google button
//   - Adaptive colors for light/dark mode
//   - Animated card appearance on load
//   - Swipe-to-dismiss gesture
//   - Keyboard-interactive scroll dismissal
//
// Navigation:
//   - On successful login: AppState updates and navigates to OverseerTabView
//   - On OAuth new user: Presents OAuthRegistrationView to complete profile

import SwiftUI
import AuthenticationServices

struct OverseerLoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = OverseerLoginViewModel()
    @FocusState private var focusedField: Field?
    @State private var hasAppeared = false

    private enum Field {
        case email
        case password
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

            Text("Overseer sign in")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Email field
            UnderlineTextField(
                label: "EMAIL",
                placeholder: "Enter your email",
                text: $viewModel.email,
                isSecure: false,
                isFocused: focusedField == .email,
                onSubmit: { focusedField = .password },
                autocapitalization: .never,
                keyboardType: .emailAddress,
                isMonospaced: false
            )
            .focused($focusedField, equals: .email)

            // Password field
            UnderlineTextField(
                label: "PASSWORD",
                placeholder: "Enter your password",
                text: $viewModel.password,
                isSecure: true,
                isFocused: focusedField == .password,
                onSubmit: { Task { viewModel.login() } }
            )
            .focused($focusedField, equals: .password)
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

    // MARK: - Buttons

    @ViewBuilder
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

        Divider()
            .padding(.vertical, AppTheme.Spacing.s)

        Text("or")
            .font(AppTheme.Typography.caption)
            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

        // Continue with Google
        Button { viewModel.signInWithGoogle() } label: {
            HStack(spacing: 10) {
                Image("GoogleLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                Text("Continue with Google")
                    .font(AppTheme.Typography.bodyMedium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(uiColor: .systemBackground))
            .foregroundStyle(Color(uiColor: .label))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color(uiColor: .separator), lineWidth: 0.5))
        }
        .buttonStyle(.plain)

        // Continue with Apple
        Button { viewModel.signInWithApple() } label: {
            HStack(spacing: 10) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 18, weight: .medium))
                Text("Continue with Apple")
                    .font(AppTheme.Typography.bodyMedium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(uiColor: .systemBackground))
            .foregroundStyle(Color(uiColor: .label))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color(uiColor: .separator), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Help

    private var helpText: some View {
        Text("Contact your event coordinator for access")
            .font(AppTheme.Typography.caption)
            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            .multilineTextAlignment(.center)
    }
}

#Preview {
    OverseerLoginView()
}
