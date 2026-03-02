//
//  DeclineReasonSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/26/26.
//

// MARK: - Decline Reason Sheet
//
// Modal sheet for entering an optional reason when declining an assignment.
// Uses the app's design system with warm background and themed styling.
//
// Features:
//   - Warm gradient background
//   - Themed text input area
//   - Styled confirm button
//   - Cancel action in toolbar
//

import SwiftUI

struct DeclineReasonSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    @Binding var reason: String
    let onConfirm: () -> Void

    @State private var isConfirming = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                // Header text
                headerSection

                // Text input
                textInputSection

                Spacer()

                // Confirm button
                confirmButton
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .themedBackground(scheme: colorScheme)
            .navigationTitle("Decline Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.themeColor)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            Text("Why are you declining?")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("Your reason helps the overseer understand your situation (optional)")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
    }

    // MARK: - Text Input Section

    private var textInputSection: some View {
        TextEditor(text: $reason)
            .font(AppTheme.Typography.body)
            .frame(minHeight: 120)
            .padding(AppTheme.Spacing.m)
            .scrollContentBackground(.hidden)
            .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .strokeBorder(
                        AppTheme.textTertiary(for: colorScheme).opacity(0.3),
                        lineWidth: 1
                    )
            )
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button {
            isConfirming = true
            HapticManager.shared.mediumTap()
            onConfirm()
            dismiss()
        } label: {
            HStack(spacing: AppTheme.Spacing.s) {
                if isConfirming {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                }
                Text("Confirm Decline")
                    .font(AppTheme.Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.ButtonHeight.medium)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .fill(AppTheme.StatusColors.declined)
            )
        }
        .disabled(isConfirming)
    }
}

// MARK: - Previews

#Preview {
    DeclineReasonSheet(reason: .constant("")) {
        print("Confirmed")
    }
}

#Preview("With Reason") {
    DeclineReasonSheet(reason: .constant("I have a conflict with another assignment")) {
        print("Confirmed")
    }
}

#Preview("Dark Mode") {
    DeclineReasonSheet(reason: .constant("")) {
        print("Confirmed")
    }
    .preferredColorScheme(.dark)
}
