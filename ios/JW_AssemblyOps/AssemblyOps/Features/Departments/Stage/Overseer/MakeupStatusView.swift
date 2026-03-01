//
//  MakeupStatusView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Makeup Status View
//
// Stage overseer view for coordinating makeup at video-based events.
// Tracks whether video is in use, supplies availability, and notes.
// State persisted locally via @AppStorage.

import SwiftUI

struct MakeupStatusView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    @AppStorage("stage.makeup.videoInUse") private var videoInUse = false
    @AppStorage("stage.makeup.disposableSupplies") private var disposableSuppliesAvailable = false
    @AppStorage("stage.makeup.notes") private var notes = ""

    private let accentColor = DepartmentColor.color(for: "STAGE")

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Video toggle card
                videoToggleCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                if videoInUse {
                    // Supplies card
                    suppliesCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // Guidelines card
                    guidelinesCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.10)

                    // Notes card
                    notesCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("stage.makeup.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Video Toggle Card

    private var videoToggleCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "video.fill")
                    .foregroundStyle(accentColor)
                Text("stage.makeup.videoToggle".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Toggle("stage.makeup.videoInUse".localized, isOn: $videoInUse)
                .font(AppTheme.Typography.body)

            if !videoInUse {
                Text("stage.makeup.videoOffHint".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Supplies Card

    private var suppliesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "bag.fill")
                    .foregroundStyle(accentColor)
                Text("stage.makeup.supplies".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Toggle("stage.makeup.disposableAvailable".localized, isOn: $disposableSuppliesAvailable)
                .font(AppTheme.Typography.body)

            Text("stage.makeup.suppliesHint".localized)
                .font(AppTheme.Typography.captionSmall)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Guidelines Card (CO-160 Ch. 3:6-8)

    private var guidelinesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "info.circle")
                    .foregroundStyle(accentColor)
                Text("stage.makeup.guidelines".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            let items = [
                "stage.makeup.guideline1".localized,
                "stage.makeup.guideline2".localized,
                "stage.makeup.guideline3".localized,
            ]

            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: AppTheme.Spacing.m) {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    Text(item)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(.primary)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Notes Card

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "note.text")
                    .foregroundStyle(accentColor)
                Text("stage.makeup.notes".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            TextEditor(text: $notes)
                .frame(minHeight: 80)
                .padding(AppTheme.Spacing.s)
                .background(accentColor.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }
}

#Preview {
    NavigationStack {
        MakeupStatusView()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        MakeupStatusView()
    }
    .preferredColorScheme(.dark)
}
