//
//  StageCrewInfoView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Stage Crew Info View
//
// Static reference content from CO-160 Chapter 3 (Stage Crew).
// Covers all five Stage crew roles: Mic Adjuster, Participant Reminder,
// Stage Configuration, Makeup Assistant, and Appearance Check.
//
// Used by: StageVolunteerDeptView (Stage crew only)

import SwiftUI

struct StageCrewInfoView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false

    private let accentColor = DepartmentColor.color(for: "STAGE")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    ForEach(Array(StageRole.allCases.enumerated()), id: \.element.id) { index, role in
                        roleCard(role)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.06)
                    }
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("stage.crew.title".localized)
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

    // MARK: - Role Card

    private func roleCard(_ role: StageRole) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: role.icon)
                    .foregroundStyle(accentColor)
                Text(role.displayName.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text(role.description)
                .font(AppTheme.Typography.body)
                .foregroundStyle(.primary)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }
}

#Preview {
    StageCrewInfoView()
}

#Preview("Dark Mode") {
    StageCrewInfoView()
        .preferredColorScheme(.dark)
}
