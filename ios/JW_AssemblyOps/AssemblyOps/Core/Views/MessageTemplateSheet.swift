//
//  MessageTemplateSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

// MARK: - Message Template Sheet
//
// Template picker grouped by category for quick message composition.
//
// Features:
//   - Templates grouped by category (Scheduling, Reminders, General)
//   - Category headers with icons
//   - Tap to select and auto-populate compose fields
//
// Used by: MessageComposeView (overseer)

import SwiftUI

struct MessageTemplateSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false

    let onSelect: (MessageTemplate) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    ForEach(MessageTemplate.TemplateCategory.allCases, id: \.self) { category in
                        let templates = MessageTemplate.templates(for: category)
                        if !templates.isEmpty {
                            categorySection(category: category, templates: templates)
                        }
                    }
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("messages.template.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("general.cancel".localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Category Section

    private func categorySection(category: MessageTemplate.TemplateCategory, templates: [MessageTemplate]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Category header
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: category.icon)
                    .foregroundStyle(AppTheme.themeColor)
                Text(category.rawValue.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            ForEach(templates) { template in
                Button {
                    HapticManager.shared.lightTap()
                    onSelect(template)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                        Text(template.title)
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(.primary)

                        Text(template.subject)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                            .lineLimit(1)

                        Text(template.body)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                }
                .buttonStyle(.plain)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
    }
}

#Preview {
    MessageTemplateSheet { template in
        print("Selected: \(template.title)")
    }
}
