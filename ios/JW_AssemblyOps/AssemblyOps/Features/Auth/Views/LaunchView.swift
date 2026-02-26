//
//  LaunchView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Launch View
//
// Splash screen displayed during app initialization.
// Shown while AppState checks for existing auth tokens.
//
// Used by: AssemblyOpsApp.swift (during initial load)

import SwiftUI

struct LaunchView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var dotPhase = false

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            // Ambient glow behind logo
            Circle()
                .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.08))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(y: -20)

            VStack(spacing: AppTheme.Spacing.xl) {
                // Logo with glow ring
                ZStack {
                    Circle()
                        .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.18 : 0.08))
                        .frame(width: 144, height: 144)

                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .shadow(color: AppTheme.themeColor.opacity(0.25), radius: 24, x: 0, y: 8)
                }
                .scaleEffect(hasAppeared ? 1.0 : 0.82)
                .opacity(hasAppeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.05), value: hasAppeared)

                VStack(spacing: AppTheme.Spacing.s) {
                    Text("AssemblyOps")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppTheme.themeColor)
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 10)
                        .animation(.easeOut(duration: 0.5).delay(0.18), value: hasAppeared)

                    Text("Volunteer Scheduling Simplified")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 8)
                        .animation(.easeOut(duration: 0.5).delay(0.24), value: hasAppeared)
                }

                // Three-dot pulsing loader
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(AppTheme.themeColor.opacity(0.5))
                            .frame(width: 7, height: 7)
                            .scaleEffect(dotPhase ? (i == 1 ? 1.4 : 1.0) : (i != 1 ? 1.4 : 1.0))
                            .animation(
                                .easeInOut(duration: 0.55)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.18),
                                value: dotPhase
                            )
                    }
                }
                .padding(.top, AppTheme.Spacing.m)
                .opacity(hasAppeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.38), value: hasAppeared)
            }
        }
        .onAppear {
            hasAppeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                dotPhase = true
            }
        }
    }
}

#Preview {
    LaunchView()
}
