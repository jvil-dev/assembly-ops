//
//  LandingView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/17/26.
//

// MARK: - Landing View
//
// Initial welcome screen shown to unauthenticated users.
// Single auth entry point — no role selection.
//
// Navigation:
//   - UnifiedLoginView: For all sign-ins
//   - RegistrationView: For new account creation

import SwiftUI

struct LandingView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showLogin = false
    @State private var showRegistration = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    AppTheme.backgroundGradient(for: colorScheme)
                        .ignoresSafeArea()

                    // Upper-right ambient glow
                    Circle()
                        .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.07))
                        .frame(width: 300, height: 300)
                        .blur(radius: 90)
                        .offset(x: geometry.size.width * 0.35, y: -geometry.size.height * 0.2)
                        .ignoresSafeArea()

                    // Lower-left secondary glow
                    Circle()
                        .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.1 : 0.04))
                        .frame(width: 200, height: 200)
                        .blur(radius: 70)
                        .offset(x: -geometry.size.width * 0.3, y: geometry.size.height * 0.25)
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        Spacer()

                        // Hero
                        heroSection
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 24)
                            .animation(.easeOut(duration: 0.55).delay(0.05), value: hasAppeared)

                        Spacer()

                        // Buttons
                        actionSection
                            .padding(.horizontal, AppTheme.Spacing.xl)
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 32)
                            .animation(.easeOut(duration: 0.55).delay(0.18), value: hasAppeared)

                        Spacer(minLength: geometry.size.height * 0.08)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation { hasAppeared = true }
            }
            .navigationDestination(isPresented: $showLogin) {
                UnifiedLoginView()
            }
            .navigationDestination(isPresented: $showRegistration) {
                RegistrationView()
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Logo with ring glow
            ZStack {
                Circle()
                    .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.22 : 0.09))
                    .frame(width: 168, height: 168)

                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: AppTheme.themeColor.opacity(0.25), radius: 20, x: 0, y: 6)
            }
            .scaleEffect(hasAppeared ? 1.0 : 1.02)
            .animation(
                .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                value: hasAppeared
            )

            VStack(spacing: AppTheme.Spacing.m) {
                Text("AssemblyOps")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(AppTheme.themeColor)
                    .tracking(0.3)

                Text("Volunteer scheduling\nmade simple.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }

    // MARK: - Buttons

    private var actionSection: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            // Primary — Sign In
            Button {
                showLogin = true
            } label: {
                HStack(spacing: AppTheme.Spacing.m) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text(NSLocalizedString("auth.signin", comment: ""))
                        .font(AppTheme.Typography.bodyMedium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.ButtonHeight.large)
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .fill(AppTheme.themeColor)
                    .shadow(color: AppTheme.themeColor.opacity(0.35), radius: 12, x: 0, y: 4)
            )
            .foregroundStyle(.white)

            // Secondary — Create Account
            Button {
                showRegistration = true
            } label: {
                HStack(spacing: AppTheme.Spacing.m) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .medium))
                    Text(NSLocalizedString("auth.createAccount", comment: ""))
                        .font(AppTheme.Typography.bodyMedium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.ButtonHeight.large)
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .stroke(AppTheme.themeColor, lineWidth: 1.5)
            )
            .foregroundStyle(AppTheme.themeColor)

            // Wordmark anchor
            Text("ASSEMBLYOPS")
                .font(.system(size: 10, weight: .medium))
                .tracking(3)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme).opacity(0.6))
                .padding(.top, AppTheme.Spacing.xs)
        }
    }
}

#Preview {
    LandingView()
}
