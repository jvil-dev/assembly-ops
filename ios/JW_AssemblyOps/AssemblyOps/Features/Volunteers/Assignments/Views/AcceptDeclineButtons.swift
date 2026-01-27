//
//  AcceptDeclineButtons.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/26/26.
//

// MARK: - Accept/Decline Buttons
//
// Action buttons for accepting or declining pending assignments.
// Uses iOS 26 Liquid Glass effect when available, with fallback styling.
//
// Features:
//   - Deadline warning banner
//   - Glass effect buttons on iOS 26+
//   - Loading state with spinner
//   - Haptic feedback on actions
//

import SwiftUI

struct AcceptDeclineButtons: View {
    @Environment(\.colorScheme) var colorScheme

    let assignment: Assignment
    let onAccept: () -> Void
    let onDecline: () -> Void

    @State private var isAccepting = false
    @State private var isDeclining = false

    var body: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            // Deadline warning
            if let deadlineText = assignment.deadlineText {
                deadlineWarning(text: deadlineText)
            }

            // Action buttons
            actionButtons
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Deadline Warning

    private func deadlineWarning(text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.StatusColors.warning)

            Text(text)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.StatusColors.warning)

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.vertical, AppTheme.Spacing.s)
        .background(AppTheme.StatusColors.warningBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.badge))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Decline button
            declineButton

            // Accept button
            acceptButton
        }
    }

    // MARK: - Decline Button

    private var declineButton: some View {
        Button {
            isDeclining = true
            HapticManager.shared.lightTap()
            onDecline()
        } label: {
            HStack(spacing: 8) {
                if isDeclining {
                    ProgressView()
                        .tint(AppTheme.StatusColors.declined)
                } else {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                }
                Text("Decline")
                    .font(AppTheme.Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.ButtonHeight.medium)
        }
        .buttonStyle(DeclineButtonStyle())
        .disabled(isAccepting || isDeclining)
    }

    // MARK: - Accept Button

    private var acceptButton: some View {
        Button {
            isAccepting = true
            HapticManager.shared.mediumTap()
            onAccept()
        } label: {
            HStack(spacing: 8) {
                if isAccepting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                }
                Text("Accept")
                    .font(AppTheme.Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.ButtonHeight.medium)
        }
        .buttonStyle(AcceptButtonStyle())
        .disabled(isAccepting || isDeclining)
    }
}

// MARK: - Button Styles

/// Decline button style - red outline with glass effect on iOS 26
private struct DeclineButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? AppTheme.StatusColors.declined : AppTheme.StatusColors.declined.opacity(0.5))
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .fill(AppTheme.StatusColors.declinedBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .strokeBorder(AppTheme.StatusColors.declined.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Accept button style - solid green with glass effect on iOS 26
private struct AcceptButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .fill(isEnabled ? AppTheme.StatusColors.accepted : AppTheme.StatusColors.accepted.opacity(0.5))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Accept/Decline Buttons") {
    VStack(spacing: 24) {
        AcceptDeclineButtons(
            assignment: .previewPending,
            onAccept: { print("Accept tapped") },
            onDecline: { print("Decline tapped") }
        )
    }
    .screenPadding()
    .themedBackground(scheme: .light)
}

#Preview("Dark Mode") {
    VStack(spacing: 24) {
        AcceptDeclineButtons(
            assignment: .previewPending,
            onAccept: { print("Accept tapped") },
            onDecline: { print("Decline tapped") }
        )
    }
    .screenPadding()
    .themedBackground(scheme: .dark)
    .preferredColorScheme(.dark)
}
