//
//  AudioWalkThroughChecklistView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - AV Walk-Through Checklist View
//
// Displays CO-160 walk-through checklists (Appendix E, F, G).
// Overseer sees all 3 checklists. Volunteers see E and F only.
// Checkable items with local state (not persisted per-item).

import SwiftUI

struct AudioWalkThroughChecklistView: View {
    var isOverseer: Bool = false

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false
    @State private var selectedChecklist: AudioChecklistType = .appendixE
    @State private var checklistItemsE: [AudioChecklistItem] = appendixEItems
    @State private var checklistItemsF: [AudioChecklistItem] = appendixFItems
    @State private var checklistPhasesG: [AudioChecklistPhase] = appendixGPhases

    private var accentColor: Color {
        if let deptType = EventSessionState.shared.selectedDepartment?.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    private var availableChecklists: [AudioChecklistType] {
        isOverseer ? AudioChecklistType.allCases : AudioChecklistType.allCases.filter { !$0.isOverseerOnly }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Checklist picker
                    Picker("", selection: $selectedChecklist) {
                        ForEach(availableChecklists, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Subtitle
                    Text(selectedChecklist.subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.03)

                    // Checklist content
                    switch selectedChecklist {
                    case .appendixE:
                        checklistSection(items: $checklistItemsE)
                    case .appendixF:
                        checklistSection(items: $checklistItemsF)
                    case .appendixG:
                        phasedChecklist
                    }
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("av.walkthrough.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("av.walkthrough.done".localized) { dismiss() }
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Simple Checklist

    private func checklistSection(items: Binding<[AudioChecklistItem]>) -> some View {
        VStack(spacing: AppTheme.Spacing.s) {
            ForEach(Array(items.wrappedValue.enumerated()), id: \.element.id) { index, item in
                Button {
                    items[index].wrappedValue.isChecked.toggle()
                    HapticManager.shared.lightTap()
                } label: {
                    HStack(spacing: AppTheme.Spacing.m) {
                        Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isChecked ? .green : AppTheme.textTertiary(for: colorScheme))
                            .font(.system(size: 20))

                        Text(item.displayText)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(item.isChecked ? AppTheme.textSecondary(for: colorScheme) : .primary)
                            .strikethrough(item.isChecked)
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.cardBackground(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                }
                .buttonStyle(.plain)
                .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.02 + 0.05)
            }
        }
    }

    // MARK: - Phased Checklist (Appendix G)

    private var phasedChecklist: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ForEach(Array(checklistPhasesG.indices), id: \.self) { phaseIndex in
                VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                    Text(checklistPhasesG[phaseIndex].displayTitle)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(accentColor)

                    ForEach(Array(checklistPhasesG[phaseIndex].items.indices), id: \.self) { itemIndex in
                        let item = checklistPhasesG[phaseIndex].items[itemIndex]
                        Button {
                            checklistPhasesG[phaseIndex].items[itemIndex].isChecked.toggle()
                            HapticManager.shared.lightTap()
                        } label: {
                            HStack(spacing: AppTheme.Spacing.m) {
                                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(item.isChecked ? .green : AppTheme.textTertiary(for: colorScheme))
                                    .font(.system(size: 20))

                                Text(item.displayText)
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(item.isChecked ? AppTheme.textSecondary(for: colorScheme) : .primary)
                                    .strikethrough(item.isChecked)
                                    .multilineTextAlignment(.leading)

                                Spacer()
                            }
                            .padding(AppTheme.Spacing.m)
                            .background(AppTheme.cardBackground(for: colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .cardPadding()
                .themedCard(scheme: colorScheme)
                .entranceAnimation(hasAppeared: hasAppeared, delay: Double(phaseIndex) * 0.05 + 0.05)
            }
        }
    }
}

#Preview("Volunteer") {
    AudioWalkThroughChecklistView(isOverseer: false)
}

#Preview("Overseer") {
    AudioWalkThroughChecklistView(isOverseer: true)
}

#Preview("Dark Mode") {
    AudioWalkThroughChecklistView(isOverseer: false)
        .preferredColorScheme(.dark)
}
