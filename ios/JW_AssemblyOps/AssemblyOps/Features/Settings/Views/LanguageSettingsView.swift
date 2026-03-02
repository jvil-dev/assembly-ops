//
//  LanguageSettingsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/25/26.
//

// MARK: - Language Settings View
//
// Full-page language selector pushed from SettingsView.
// Shows list of available languages with checkmark for current selection.
// Changes apply immediately via LocalizationManager.

import SwiftUI

struct LanguageSettingsView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    private let languages: [(code: String, name: String, nativeName: String)] = [
        ("en", "English", "English"),
        ("es", "Spanish", "Español"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.m) {
                ForEach(Array(languages.enumerated()), id: \.element.code) { index, lang in
                    languageRow(lang)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.05)
                }

                Text("settings.language.note".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.top, AppTheme.Spacing.m)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("settings.language".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) { hasAppeared = true }
        }
    }

    private func languageRow(_ lang: (code: String, name: String, nativeName: String)) -> some View {
        let isSelected = localizationManager.currentLanguage == lang.code

        return Button {
            HapticManager.shared.lightTap()
            localizationManager.currentLanguage = lang.code
        } label: {
            HStack(spacing: AppTheme.Spacing.m) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(lang.nativeName)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(.primary)
                    Text(lang.name)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.themeColor)
                }
            }
            .cardPadding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.cardBackground(for: colorScheme))
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .strokeBorder(isSelected ? AppTheme.themeColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
}
