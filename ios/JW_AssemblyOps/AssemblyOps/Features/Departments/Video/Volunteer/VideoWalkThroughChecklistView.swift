//
//  VideoWalkThroughChecklistView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Video Walk-Through Checklist View
//
// Displays CO-160 walk-through checklists for the Video crew.
// Appendix A: JW Library & Media Playlists (phased)
// Appendix B: Audio & Video System Configuration (flat list)
// Appendix D: JW Stream Procedures (phased)
// Appendix G: AV Overseer Checklist (phased, overseer only)
//
// Overseer sees all (A + B + D + G). Volunteers see A + B + D only.
// Checkable items with local state (not persisted).

import SwiftUI

struct VideoWalkThroughChecklistView: View {
    var isOverseer: Bool = false

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false
    @State private var selectedChecklist: VideoChecklistType = .appendixA
    @State private var checklistPhasesA: [AudioChecklistPhase] = videoAppendixAPhases
    @State private var checklistItemsB: [AudioChecklistItem] = videoAppendixBItems
    @State private var checklistPhasesD: [AudioChecklistPhase] = videoAppendixDPhases
    @State private var checklistPhasesG: [AudioChecklistPhase] = videoAppendixGPhases

    private let accentColor = DepartmentColor.color(for: "VIDEO")

    private var availableChecklists: [VideoChecklistType] {
        isOverseer ? VideoChecklistType.allCases : VideoChecklistType.allCases.filter { !$0.isOverseerOnly }
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

                    Text(selectedChecklist.subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.03)

                    // Checklist content
                    switch selectedChecklist {
                    case .appendixA:
                        phasedChecklist(phases: $checklistPhasesA)
                    case .appendixB:
                        checklistSection(items: $checklistItemsB)
                    case .appendixD:
                        phasedChecklist(phases: $checklistPhasesD)
                    case .appendixG:
                        phasedChecklist(phases: $checklistPhasesG)
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

    // MARK: - Phased Checklist

    private func phasedChecklist(phases: Binding<[AudioChecklistPhase]>) -> some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ForEach(Array(phases.wrappedValue.indices), id: \.self) { phaseIndex in
                VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                    Text(phases[phaseIndex].wrappedValue.displayTitle)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(accentColor)

                    ForEach(Array(phases[phaseIndex].wrappedValue.items.indices), id: \.self) { itemIndex in
                        let item = phases[phaseIndex].wrappedValue.items[itemIndex]
                        Button {
                            phases[phaseIndex].wrappedValue.items[itemIndex].isChecked.toggle()
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
    VideoWalkThroughChecklistView(isOverseer: false)
}

#Preview("Overseer") {
    VideoWalkThroughChecklistView(isOverseer: true)
}

#Preview("Dark Mode") {
    VideoWalkThroughChecklistView(isOverseer: false)
        .preferredColorScheme(.dark)
}
