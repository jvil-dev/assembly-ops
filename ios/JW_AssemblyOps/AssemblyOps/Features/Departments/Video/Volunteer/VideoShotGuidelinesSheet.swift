//
//  VideoShotGuidelinesSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Video Shot Guidelines Sheet
//
// Static reference content summarizing CO-160 Chapter 4 shot types
// and framing guidelines for camera operators.
//
// Used by: VideoVolunteerDeptView (Video crew only)

import SwiftUI

struct VideoShotGuidelinesSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false

    private let accentColor = DepartmentColor.color(for: "VIDEO")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    ForEach(Array(VideoShotType.allCases.enumerated()), id: \.element) { index, shot in
                        shotCard(shot)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.06)
                    }

                    // General guidelines card
                    generalGuidelinesCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: Double(VideoShotType.allCases.count) * 0.06)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("video.volunteer.shotGuidelines".localized)
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

    // MARK: - Shot Type Card

    private func shotCard(_ shot: VideoShotType) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: shot.icon)
                    .foregroundStyle(accentColor)
                Text(shot.displayName.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text(shot.description)
                .font(AppTheme.Typography.body)
                .foregroundStyle(.primary)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - General Guidelines Card

    private var generalGuidelinesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "lightbulb")
                    .foregroundStyle(accentColor)
                Text("video.shot.generalGuidelines".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            let guidelines = [
                "video.shot.guideline.followDirector".localized,
                "video.shot.guideline.avoidZoom".localized,
                "video.shot.guideline.steadyMovement".localized,
                "video.shot.guideline.checkMonitor".localized,
            ]

            ForEach(Array(guidelines.enumerated()), id: \.offset) { _, item in
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
    VideoShotGuidelinesSheet()
}

#Preview("Dark Mode") {
    VideoShotGuidelinesSheet()
        .preferredColorScheme(.dark)
}
