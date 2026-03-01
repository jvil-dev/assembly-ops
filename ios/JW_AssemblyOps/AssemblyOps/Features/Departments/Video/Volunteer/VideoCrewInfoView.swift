//
//  VideoCrewInfoView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Video Crew Info View
//
// Static reference content from CO-160 Chapter 4 (Video Crew).
// Covers Technical Director, Switcher Operator, Media Operator,
// Camera Operator, and Recording Monitor roles (paras 21-39).
//
// Used by: VideoVolunteerDeptView (Video crew only)

import SwiftUI

struct VideoCrewInfoView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false

    private let accentColor = DepartmentColor.color(for: "VIDEO")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Technical Director (CO-160 Ch. 4:21-24)
                    infoCard(
                        icon: "rectangle.on.rectangle.angled",
                        title: "video.crew.roles.technicalDirector.title".localized,
                        items: [
                            "video.crew.roles.technicalDirector.item1".localized,
                            "video.crew.roles.technicalDirector.item2".localized,
                            "video.crew.roles.technicalDirector.item3".localized,
                        ]
                    )
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Switcher Operator (CO-160 Ch. 4:25-27)
                    infoCard(
                        icon: "slider.vertical.3",
                        title: "video.crew.roles.switcherOp.title".localized,
                        items: [
                            "video.crew.roles.switcherOp.item1".localized,
                            "video.crew.roles.switcherOp.item2".localized,
                            "video.crew.roles.switcherOp.item3".localized,
                        ]
                    )
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // Media Operator (CO-160 Ch. 4:28-31)
                    infoCard(
                        icon: "play.rectangle",
                        title: "video.crew.roles.mediaOp.title".localized,
                        items: [
                            "video.crew.roles.mediaOp.item1".localized,
                            "video.crew.roles.mediaOp.item2".localized,
                            "video.crew.roles.mediaOp.item3".localized,
                        ]
                    )
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.10)

                    // Camera Operator (CO-160 Ch. 4:32-36)
                    infoCard(
                        icon: "video",
                        title: "video.crew.roles.cameraOp.title".localized,
                        items: [
                            "video.crew.roles.cameraOp.item1".localized,
                            "video.crew.roles.cameraOp.item2".localized,
                            "video.crew.roles.cameraOp.item3".localized,
                            "video.crew.roles.cameraOp.item4".localized,
                        ]
                    )
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)

                    // Recording Monitor (CO-160 Ch. 4:37-39)
                    infoCard(
                        icon: "eye",
                        title: "video.crew.roles.recordingMonitor.title".localized,
                        items: [
                            "video.crew.roles.recordingMonitor.item1".localized,
                            "video.crew.roles.recordingMonitor.item2".localized,
                        ]
                    )
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.20)

                    // Safety guidelines (shared AV concerns)
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
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.25)

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
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.30)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("video.crew.title".localized)
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
    VideoCrewInfoView()
}

#Preview("Dark Mode") {
    VideoCrewInfoView()
        .preferredColorScheme(.dark)
}
