//
//  AccessCodeDisplayView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/26/26.
//

// MARK: - Access Code Display View
//
// Shown after a successful department purchase.
// Displays the generated access code prominently with copy + share options.
// The overseer shares this code with volunteers to join the department.
//

import SwiftUI

struct AccessCodeDisplayView: View {
    let departmentName: String
    let accessCode: String
    let eventName: String
    var onDone: (() -> Void)?

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Success icon
                successHeader
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                // Access code card
                accessCodeCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

                // Instructions
                instructionsCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)

                // Done button
                Button {
                    if let onDone { onDone() } else { dismiss() }
                } label: {
                    Text("accessCode.done".localized)
                        .font(AppTheme.Typography.bodyMedium)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.ButtonHeight.large)
                        .background(AppTheme.themeColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                }
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.2)
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.xxl)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("accessCode.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) { hasAppeared = true }
        }
    }

    // MARK: - Success Header

    private var successHeader: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(AppTheme.StatusColors.acceptedBackground)
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.StatusColors.accepted)
            }

            VStack(spacing: AppTheme.Spacing.s) {
                Text("accessCode.success.title".localized)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)

                Text(String(format: "accessCode.success.subtitle".localized, departmentName, eventName))
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Access Code Card

    private var accessCodeCard: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "key.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("accessCode.label".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text(accessCode)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
                .tracking(2)

            HStack(spacing: AppTheme.Spacing.m) {
                Button {
                    UIPasteboard.general.string = accessCode
                    copied = true
                    HapticManager.shared.success()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                } label: {
                    HStack(spacing: AppTheme.Spacing.s) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "accessCode.copied".localized : "accessCode.copy".localized)
                            .font(AppTheme.Typography.bodyMedium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.ButtonHeight.small)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                            .stroke(AppTheme.themeColor, lineWidth: 1.5)
                    )
                    .foregroundStyle(AppTheme.themeColor)
                }

                ShareLink(item: String(format: "accessCode.share.message".localized, accessCode, departmentName, eventName)) {
                    HStack(spacing: AppTheme.Spacing.s) {
                        Image(systemName: "square.and.arrow.up")
                        Text("accessCode.share".localized)
                            .font(AppTheme.Typography.bodyMedium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.ButtonHeight.small)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                            .fill(AppTheme.themeColor)
                    )
                    .foregroundStyle(.white)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Instructions

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "info.circle")
                    .foregroundStyle(AppTheme.themeColor)
                Text("accessCode.instructions.title".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                instructionRow(number: "1", text: "accessCode.instructions.step1".localized)
                instructionRow(number: "2", text: "accessCode.instructions.step2".localized)
                instructionRow(number: "3", text: "accessCode.instructions.step3".localized)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(AppTheme.themeColor.opacity(0.12))
                    .frame(width: 24, height: 24)
                Text(number)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.themeColor)
            }

            Text(text)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
    }
}
