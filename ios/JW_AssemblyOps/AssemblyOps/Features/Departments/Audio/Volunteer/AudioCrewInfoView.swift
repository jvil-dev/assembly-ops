//
//  AudioCrewInfoView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Audio Crew Info View
//
// Static reference content from CO-160 Chapter 2 (Audio Crew).
// Covers Mixer Operator and Mixer Operator Assistant roles
// plus safety and equipment handling reminders.
//
// Used by: AudioVolunteerDeptView (Audio crew only)

import SwiftUI

struct AudioCrewInfoView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false

    private let accentColor = DepartmentColor.color(for: "AUDIO")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Mixer Operator role (CO-160 Ch. 2:15)
                    infoCard(
                        icon: "slider.horizontal.3",
                        title: "audio.crew.roles.mixerOp.title".localized,
                        items: [
                            "audio.crew.roles.mixerOp.item1".localized,
                            "audio.crew.roles.mixerOp.item2".localized,
                            "audio.crew.roles.mixerOp.item3".localized,
                            "audio.crew.roles.mixerOp.item4".localized,
                        ]
                    )
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Mixer Operator Assistant role (CO-160 Ch. 2:16)
                    infoCard(
                        icon: "headphones",
                        title: "audio.crew.roles.mixerOpAsst.title".localized,
                        items: [
                            "audio.crew.roles.mixerOpAsst.item1".localized,
                            "audio.crew.roles.mixerOpAsst.item2".localized,
                            "audio.crew.roles.mixerOpAsst.item3".localized,
                        ]
                    )
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // Assistive Listening Device Operator (CO-160 Ch. 2:17-18)
                    infoCard(
                        icon: "ear",
                        title: "audio.crew.roles.assistiveListening.title".localized,
                        items: [
                            "audio.crew.roles.assistiveListening.item1".localized,
                            "audio.crew.roles.assistiveListening.item2".localized,
                            "audio.crew.roles.assistiveListening.item3".localized,
                        ]
                    )
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.10)

                    // Loudspeaker Operator (CO-160 Ch. 2:19)
                    infoCard(
                        icon: "speaker.wave.3",
                        title: "audio.crew.roles.loudspeaker.title".localized,
                        items: [
                            "audio.crew.roles.loudspeaker.item1".localized,
                            "audio.crew.roles.loudspeaker.item2".localized,
                            "audio.crew.roles.loudspeaker.item3".localized,
                        ]
                    )
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)

                    // Safety guidelines
                    infoCard(
                        icon: "shield.checkered",
                        title: "av.crew.safety.title".localized,
                        items: [
                            "av.crew.safety.ppe".localized,
                            "av.crew.safety.lifting".localized,
                            "av.crew.safety.electrical".localized,
                            "av.crew.safety.ladders".localized,
                            "av.crew.safety.report".localized,
                        ]
                    )
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.20)

                    // Equipment handling
                    infoCard(
                        icon: "shippingbox",
                        title: "av.crew.equipment.title".localized,
                        items: [
                            "av.crew.equipment.careful".localized,
                            "av.crew.equipment.checkout".localized,
                            "av.crew.equipment.damage".localized,
                            "av.crew.equipment.storage".localized,
                        ]
                    )
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.25)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("audio.crew.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("av.crew.done".localized) { dismiss() }
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Info Card

    private func infoCard(icon: String, title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: icon)
                    .foregroundStyle(accentColor)
                Text(title.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

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
}

#Preview {
    AudioCrewInfoView()
}

#Preview("Dark Mode") {
    AudioCrewInfoView()
        .preferredColorScheme(.dark)
}
