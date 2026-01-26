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
//
// Components:
//   - backgroundGradient: Adaptive gradient background
//   - cardContent: Main login card with form and buttons
//   - formSection: Email and password text fields
//   - oauthSection: Apple and Google sign-in buttons
//

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
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                hasAppeared = true
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
        VStack(spacing: 32) {
            headerSection
            formSection
            errorSection
            loginButton
            helpText
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .shadow(color: Color("ThemeColor").opacity(0.15), radius: 12, x: 0, y: 4)

            Text("AssemblyOps")
                .font(.system(size: 28, weight: .semibold, design: .default))
                .foregroundStyle(Color("ThemeColor"))
                .tracking(0.5)

            Text("Overseer sign in")
                .font(.subheadline)
                .foregroundStyle(textSecondary)
        }
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: 24) {
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
            HStack(spacing: 8) {
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

        Divider()
            .padding(.vertical, 8)

        Text("or")
            .font(.footnote)
            .foregroundStyle(.secondary)

        // Sign in with Apple
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { _ in
            // We handle this via our own tap gesture
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture { viewModel.signInWithApple() }

        // Google Sign-In
        Button { viewModel.signInWithGoogle() } label: {
            HStack {
                Image(systemName: "globe")
                    .font(.system(size: 20))
                Text("Sign in with Google")
                    .font(.system(size: 17, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.gray.opacity(0.3))
            )
        }
        .foregroundStyle(colorScheme == .dark ? .white : .black)
    }

    // MARK: - Help

    private var helpText: some View {
        Text("Contact your event coordinator for access")
            .font(.footnote)
            .foregroundStyle(textSecondary)
            .multilineTextAlignment(.center)
    }
}

#Preview {
    OverseerLoginView()
}
