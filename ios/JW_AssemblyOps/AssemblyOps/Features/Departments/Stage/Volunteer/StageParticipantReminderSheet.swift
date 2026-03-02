//
//  StageParticipantReminderSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Stage Participant Reminder Sheet
//
// Ephemeral Appendix F checklist for giving pre-stage reminders to participants.
// Stage crew uses this immediately before each participant goes on stage.
// State resets on dismiss — not persisted to the backend.

import SwiftUI

struct StageParticipantReminderSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var participantName = ""
    @State private var checklistItems: [AudioChecklistItem] = stagePreShowItems
    @State private var hasAppeared = false

    private let accentColor = DepartmentColor.color(for: "STAGE")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Checklist card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        HStack(spacing: AppTheme.Spacing.s) {
                            Image(systemName: "checklist")
                                .foregroundStyle(accentColor)
                            Text(StageChecklistType.preShow.displayName.uppercased())
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

                        Text(StageChecklistType.preShow.subtitle)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                        VStack(spacing: AppTheme.Spacing.s) {
                            ForEach(Array(checklistItems.enumerated()), id: \.element.id) { index, item in
                                Button {
                                    checklistItems[index].isChecked.toggle()
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
                    }
                    .cardPadding()
                    .themedCard(scheme: colorScheme)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // Done button
                    Button {
                        HapticManager.shared.success()
                        dismiss()
                    } label: {
                        Text("stage.preShow.done".localized)
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.m)
                            .background(allChecked ? accentColor : AppTheme.textTertiary(for: colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                    }
                    .buttonStyle(.plain)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("stage.volunteer.participantChecklist".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
            }
        }
    }

    private var allChecked: Bool {
        checklistItems.allSatisfy { $0.isChecked }
    }
}

#Preview {
    StageParticipantReminderSheet()
}

#Preview("Dark Mode") {
    StageParticipantReminderSheet()
        .preferredColorScheme(.dark)
}
