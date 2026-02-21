//
//  OverseerRegistrationView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Overseer Registration View
//
// Full registration form for creating a new overseer account.
// Supports email/password registration and OAuth (Apple/Google) sign-up.
//
// Sections:
//   - Header: Logo and title
//   - Registration Form: Email, password, name, phone, congregation fields
//   - OAuth Buttons: Sign in with Apple and Google options
//   - Error Display: Shows validation/submission errors
//
// Features:
//   - Warm gradient background matching login views
//   - Floating card with layered shadows
//   - Entrance animation on appear
//   - Form validation via OverseerRegistrationViewModel.isFormValid
//   - Password confirmation matching
//   - Minimum 8 character password requirement
//   - OAuth flow triggers OAuthRegistrationView for profile completion
//
// Navigation:
//   - Presented as navigation destination from LandingView
//   - Full screen cover for OAuthRegistrationView when OAuth user needs completion
//

import SwiftUI
import AuthenticationServices

struct OverseerRegistrationView: View {
    @StateObject private var viewModel = OverseerRegistrationViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @FocusState private var focusedField: Field?
    @State private var hasAppeared = false

    private enum Field: Hashable {
        case email
        case password
        case confirmPassword
        case firstName
        case lastName
    }

    // MARK: - Adaptive Colors

    private var backgroundTop: Color {
        colorScheme == .dark
            ? Color(white: 0.1)
            : Color(red: 0.98, green: 0.97, blue: 0.95)
    }

    private var backgroundBottom: Color {
        colorScheme == .dark
            ? Color(white: 0.08)
            : Color(red: 0.96, green: 0.94, blue: 0.91)
    }

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color(white: 0.15)
            : Color.white
    }

    private var textSecondary: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.6)
            : Color(red: 0.45, green: 0.45, blue: 0.45)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient

                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: geometry.size.height * 0.04)

                        cardContent
                            .padding(.horizontal, 28)

                        Spacer(minLength: geometry.size.height * 0.04)
                    }
                    .frame(minHeight: geometry.size.height)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width > 100 && abs(value.translation.height) < 100 {
                        dismiss()
                    }
                }
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                hasAppeared = true
            }
        }
        .fullScreenCover(isPresented: $viewModel.showOAuthRegistration) {
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

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Card

    private var cardContent: some View {
        VStack(spacing: 28) {
            headerSection
            formSection
            errorSection
            createButton
            dividerSection
            oauthButtons
            helpText
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 32)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .shadow(color: Color("ThemeColor").opacity(0.15), radius: 12, x: 0, y: 4)

            Text("Create Account")
                .font(.system(size: 24, weight: .semibold, design: .default))
                .foregroundStyle(Color("ThemeColor"))
                .tracking(0.3)

            Text("Register as an event overseer")
                .font(.subheadline)
                .foregroundStyle(textSecondary)
        }
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: 20) {
            // Email
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

            // Password
            UnderlineTextField(
                label: "PASSWORD",
                placeholder: "Minimum 8 characters",
                text: $viewModel.password,
                isSecure: true,
                isFocused: focusedField == .password,
                onSubmit: { focusedField = .confirmPassword }
            )
            .focused($focusedField, equals: .password)

            // Confirm Password
            UnderlineTextField(
                label: "CONFIRM PASSWORD",
                placeholder: "Re-enter your password",
                text: $viewModel.confirmPassword,
                isSecure: true,
                isFocused: focusedField == .confirmPassword,
                onSubmit: { focusedField = .firstName }
            )
            .focused($focusedField, equals: .confirmPassword)

            // Password match indicator
            if !viewModel.confirmPassword.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.caption)
                    Text(viewModel.passwordsMatch ? "Passwords match" : "Passwords don't match")
                        .font(.caption)
                }
                .foregroundStyle(viewModel.passwordsMatch ? Color.green : Color.red.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
            }

            // First Name
            UnderlineTextField(
                label: "FIRST NAME",
                placeholder: "Enter your first name",
                text: $viewModel.firstName,
                isSecure: false,
                isFocused: focusedField == .firstName,
                onSubmit: { focusedField = .lastName },
                autocapitalization: .words,
                isMonospaced: false
            )
            .focused($focusedField, equals: .firstName)

            // Last Name
            UnderlineTextField(
                label: "LAST NAME",
                placeholder: "Enter your last name",
                text: $viewModel.lastName,
                isSecure: false,
                isFocused: focusedField == .lastName,
                onSubmit: { viewModel.register() },
                autocapitalization: .words,
                isMonospaced: false
            )
            .focused($focusedField, equals: .lastName)
        }
    }

    // MARK: - Error

    @ViewBuilder
    private var errorSection: some View {
        if let error = viewModel.errorMessage {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.subheadline)
                Text(error)
                    .font(.subheadline)
            }
            .foregroundStyle(Color(red: 0.8, green: 0.25, blue: 0.2))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.8, green: 0.25, blue: 0.2).opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    // MARK: - Create Button

    private var createButton: some View {
        Button {
            viewModel.register()
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Create Account")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(viewModel.isFormValid ? Color("ThemeColor") : Color("ThemeColor").opacity(0.4))
        )
        .foregroundStyle(.white)
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isFormValid)
    }

    // MARK: - Divider

    private var dividerSection: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            Text("or")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
    }

    // MARK: - OAuth Buttons

    private var oauthButtons: some View {
        VStack(spacing: 12) {
            // Continue with Google
            Button { viewModel.signInWithGoogle() } label: {
                HStack(spacing: 10) {
                    Image("GoogleLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                    Text("Continue with Google")
                        .font(.system(size: 17, weight: .medium))
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
                        .font(.system(size: 17, weight: .medium))
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
    }

    // MARK: - Help Text

    private var helpText: some View {
        Text("By creating an account, you agree to our Terms of Service")
            .font(.footnote)
            .foregroundStyle(textSecondary)
            .multilineTextAlignment(.center)
    }
}

#Preview {
    NavigationStack {
        OverseerRegistrationView()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        OverseerRegistrationView()
    }
    .preferredColorScheme(.dark)
}
