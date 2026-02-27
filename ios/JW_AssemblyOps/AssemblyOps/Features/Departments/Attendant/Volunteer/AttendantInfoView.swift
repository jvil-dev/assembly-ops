//
//  AttendantInfoView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/21/26.
//

// MARK: - Attendant Info View
//
// Read-only sheet displaying CO-23 quick-reference reminders for attendant
// volunteers. Organized into expandable themed cards by topic. Presented
// from the HomeView toolbar (? button) for attendant department volunteers.
//

import SwiftUI

struct AttendantInfoView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false
    @State private var expandedSections: Set<String> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Header
                    headerCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Expandable sections
                    ForEach(Array(AttendantInfoContent.sections.enumerated()), id: \.element.id) { index, section in
                        sectionCard(section, delay: Double(index + 1) * 0.05)
                    }

                    // Source footer
                    sourceFooter
                        .entranceAnimation(hasAppeared: hasAppeared, delay: Double(AttendantInfoContent.sections.count + 1) * 0.05)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("attendant.info.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.done".localized) { dismiss() }
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(AppTheme.themeColor)
                    .font(.system(size: 20))
                Text("attendant.info.title".localized)
                    .font(AppTheme.Typography.title)
                    .foregroundStyle(.primary)
            }
            Text("attendant.info.subtitle".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Section Card

    private func sectionCard(_ section: AttendantInfoSection, delay: Double) -> some View {
        let isExpanded = expandedSections.contains(section.id)

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Tappable header row
            Button {
                withAnimation(AppTheme.quickAnimation) {
                    if isExpanded {
                        expandedSections.remove(section.id)
                    } else {
                        expandedSections.insert(section.id)
                    }
                }
                HapticManager.shared.lightTap()
            } label: {
                HStack {
                    HStack(spacing: AppTheme.Spacing.s) {
                        Image(systemName: section.icon)
                            .foregroundStyle(AppTheme.themeColor)
                        Text(section.titleKey.localized)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            // Expandable content
            if isExpanded {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                    ForEach(section.reminders) { reminder in
                        reminderRow(reminder)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .entranceAnimation(hasAppeared: hasAppeared, delay: delay)
    }

    // MARK: - Reminder Row

    private func reminderRow(_ reminder: AttendantReminder) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.s) {
            Circle()
                .fill(reminder.isHighlighted ? Color.red : AppTheme.themeColor)
                .frame(width: 6, height: 6)
                .padding(.top, 7)

            Text(reminder.id.localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(reminder.isHighlighted ? .primary : AppTheme.textSecondary(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Source Footer

    private var sourceFooter: some View {
        Text("attendant.info.source".localized)
            .font(AppTheme.Typography.caption)
            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            .frame(maxWidth: .infinity)
            .padding(.top, AppTheme.Spacing.m)
    }
}

#Preview {
    AttendantInfoView()
}

#Preview("Dark Mode") {
    AttendantInfoView()
        .preferredColorScheme(.dark)
}
