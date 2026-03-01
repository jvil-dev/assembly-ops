//
//  StageConfigurationView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Stage Configuration View
//
// Stage overseer view for recording stage layout details.
// Entry/exit sides, furniture notes, and floor marking confirmation.
// State persisted locally via @AppStorage keyed by eventId.

import SwiftUI

struct StageConfigurationView: View {
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    // Persisted locally by event
    private var storageKey: String {
        "stage.config.\(sessionState.selectedEvent?.id ?? "default")"
    }

    @AppStorage("stage.config.entryIsLeft") private var entryIsLeft = true
    @AppStorage("stage.config.exitIsLeft") private var exitIsLeft = false
    @AppStorage("stage.config.bothSidesEntry") private var bothSidesEntry = false
    @AppStorage("stage.config.floorMarksConfirmed") private var floorMarksConfirmed = false
    @AppStorage("stage.config.confidenceMonitorChecked") private var confidenceMonitorChecked = false
    @AppStorage("stage.config.furnitureNotes") private var furnitureNotes = ""
    @AppStorage("stage.config.additionalNotes") private var additionalNotes = ""

    private let accentColor = DepartmentColor.color(for: "STAGE")

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Entry/Exit sides card
                sidesCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                // Confirmations card
                confirmationsCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                // Furniture notes card
                furnitureNotesCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.10)

                // Additional notes card
                additionalNotesCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("stage.config.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Entry/Exit Sides Card

    private var sidesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundStyle(accentColor)
                Text("stage.config.sides".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Toggle("stage.config.bothSidesEntry".localized, isOn: $bothSidesEntry)
                .font(AppTheme.Typography.body)

            if !bothSidesEntry {
                Divider()

                VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                    Text("stage.config.entryLabel".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Picker("", selection: $entryIsLeft) {
                        Text("stage.config.leftSide".localized).tag(true)
                        Text("stage.config.rightSide".localized).tag(false)
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                    Text("stage.config.exitLabel".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Picker("", selection: $exitIsLeft) {
                        Text("stage.config.leftSide".localized).tag(true)
                        Text("stage.config.rightSide".localized).tag(false)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Confirmations Card

    private var confirmationsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "checkmark.seal")
                    .foregroundStyle(accentColor)
                Text("stage.config.confirmations".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Toggle("stage.config.floorMarks".localized, isOn: $floorMarksConfirmed)
                .font(AppTheme.Typography.body)
            Toggle("stage.config.confidenceMonitor".localized, isOn: $confidenceMonitorChecked)
                .font(AppTheme.Typography.body)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Furniture Notes Card

    private var furnitureNotesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "chair")
                    .foregroundStyle(accentColor)
                Text("stage.config.furnitureNotes".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            TextEditor(text: $furnitureNotes)
                .frame(minHeight: 100)
                .padding(AppTheme.Spacing.s)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

            Text("stage.config.furnitureHint".localized)
                .font(AppTheme.Typography.captionSmall)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Additional Notes Card

    private var additionalNotesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "note.text")
                    .foregroundStyle(accentColor)
                Text("stage.config.additionalNotes".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            TextEditor(text: $additionalNotes)
                .frame(minHeight: 80)
                .padding(AppTheme.Spacing.s)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }
}

#Preview {
    NavigationStack {
        StageConfigurationView()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        StageConfigurationView()
    }
    .preferredColorScheme(.dark)
}
