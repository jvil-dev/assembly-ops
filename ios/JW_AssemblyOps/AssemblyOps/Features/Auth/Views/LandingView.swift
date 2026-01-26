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
//
// Components:
//   - backgroundGradient: Adaptive gradient background
//   - headerSection: Logo and app name display
//   - loginOptions: Role selection buttons
//

import SwiftUI

struct LandingView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showVolunteerLogin = false
    @State private var showOverseerLogin = false
    @State private var showOverseerRegistration = false

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

    private var textSecondary: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.6)
            : Color(red: 0.45, green: 0.45, blue: 0.45)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    backgroundGradient

                    VStack(spacing: 0) {
                        Spacer()

                        // Header
                        headerSection
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)

                        Spacer()

                        // Login Options
                        loginOptions
                            .padding(.horizontal, 32)
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 30)

                        Spacer()
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.easeOut(duration: 0.7).delay(0.1)) {
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

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 20) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .shadow(color: Color("ThemeColor").opacity(0.2), radius: 16, x: 0, y: 6)

            VStack(spacing: 8) {
                Text("AssemblyOps")
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .foregroundStyle(Color("ThemeColor"))
                    .tracking(0.5)

                Text("Volunteer scheduling made simple")
                    .font(.subheadline)
                    .foregroundStyle(textSecondary)
            }
        }
    }

    // MARK: - Login Options

    private var loginOptions: some View {
        VStack(spacing: 16) {
            // Volunteer Button
            Button {
                showVolunteerLogin = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .medium))
                    Text("Sign in as Volunteer")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("ThemeColor"))
            )
            .foregroundStyle(.white)

            // Overseer Button
            Button {
                showOverseerLogin = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 18, weight: .medium))
                    Text("Sign in as Overseer")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color("ThemeColor"), lineWidth: 2)
            )
            .foregroundStyle(Color("ThemeColor"))
            
            // Registration link for new overseers
            Button {
                showOverseerRegistration = true
            } label: {
                Text("New overseer? Register here")
                    .font(.footnote)
                    .foregroundStyle(Color("ThemeColor"))
            }
            .padding(.top, 8)
        }
        .navigationDestination(isPresented: $showOverseerRegistration) {
            OverseerRegistrationView()
        }
    }
}

#Preview {
    LandingView()
}
