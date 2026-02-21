//
//  LandingView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/17/26.
//

// MARK: - Landing View
//
// Initial welcome screen shown to unauthenticated users.
// Provides navigation to volunteer login and overseer login/registration.
//
// Features:
//   - App logo and branding header
//   - Volunteer login button (primary action)
//   - Overseer login and registration buttons
//   - Adaptive colors for light/dark mode
//   - Animated appearance on load
//
// Navigation:
//   - VolunteerLoginView: For volunteers with ID and token
//   - OverseerLoginView: For overseers with email/password or OAuth
//   - OverseerRegistrationView: For new overseer account creation

import SwiftUI

struct LandingView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showVolunteerLogin = false
    @State private var showOverseerLogin = false
    @State private var showOverseerRegistration = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    AppTheme.backgroundGradient(for: colorScheme)
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        Spacer()

                        // Header
                        headerSection
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)

                        Spacer()

                        // Login Options
                        loginOptions
                            .padding(.horizontal, AppTheme.Spacing.xxl)
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 30)

                        Spacer()
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
            .navigationDestination(isPresented: $showVolunteerLogin) {
                VolunteerLoginView()
            }
            .navigationDestination(isPresented: $showOverseerLogin) {
                OverseerLoginView()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .shadow(color: AppTheme.themeColor.opacity(0.2), radius: 16, x: 0, y: 6)

            VStack(spacing: AppTheme.Spacing.s) {
                Text("AssemblyOps")
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .foregroundStyle(AppTheme.themeColor)
                    .tracking(0.5)

                Text("Volunteer scheduling made simple")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
    }

    // MARK: - Login Options

    private var loginOptions: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            // Volunteer Button
            Button {
                showVolunteerLogin = true
            } label: {
                HStack(spacing: AppTheme.Spacing.m) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .medium))
                    Text("Sign in as Volunteer")
                        .font(AppTheme.Typography.bodyMedium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.ButtonHeight.large)
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .fill(AppTheme.themeColor)
            )
            .foregroundStyle(.white)

            // Overseer Button
            Button {
                showOverseerLogin = true
            } label: {
                HStack(spacing: AppTheme.Spacing.m) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 18, weight: .medium))
                    Text("Sign in as Overseer")
                        .font(AppTheme.Typography.bodyMedium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.ButtonHeight.large)
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .stroke(AppTheme.themeColor, lineWidth: 2)
            )
            .foregroundStyle(AppTheme.themeColor)

            // Registration link for new overseers
            Button {
                showOverseerRegistration = true
            } label: {
                Text("New overseer? Register here")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.themeColor)
            }
            .padding(.top, AppTheme.Spacing.s)
        }
        .navigationDestination(isPresented: $showOverseerRegistration) {
            OverseerRegistrationView()
        }
    }
}

#Preview {
    LandingView()
}
