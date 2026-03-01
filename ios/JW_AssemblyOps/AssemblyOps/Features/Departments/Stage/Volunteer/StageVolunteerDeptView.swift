//
//  StageVolunteerDeptView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Stage Volunteer Department View
//
// Hub for Stage crew volunteers. Shows quick actions for the
// participant reminder checklist (Appendix F) and crew role info.
//
// Used by: DepartmentTabRouter (for STAGE volunteers)

import SwiftUI

struct StageVolunteerDeptView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showParticipantChecklist = false
    @State private var showCrewInfo = false

    private let accentColor = DepartmentColor.color(for: "STAGE")

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Your Role
                roleCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                // Quick Actions
                quickActionsCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                // Key Reminders
                remindersCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.10)

                // Resources
                resourcesCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("stage.dashboard.title".localized)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showParticipantChecklist) {
            StageParticipantReminderSheet()
        }
        .sheet(isPresented: $showCrewInfo) {
            StageCrewInfoView()
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Role Card

    private var roleCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "person.fill")
                    .foregroundStyle(accentColor)
                Text("stage.volunteer.yourRole".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                Text("stage.volunteer.roleTitle".localized)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
                Text("stage.volunteer.roleDesc".localized)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Quick Actions Card

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(accentColor)
                Text("stage.volunteer.quickActions".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Button {
                showParticipantChecklist = true
                HapticManager.shared.lightTap()
            } label: {
                actionRow(
                    icon: "checklist",
                    title: "stage.volunteer.participantChecklist".localized,
                    color: accentColor
                )
            }
            .buttonStyle(.plain)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Key Reminders Card

    private var remindersCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("stage.volunteer.keyReminders".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            VStack(spacing: AppTheme.Spacing.s) {
                reminderRow(icon: "clock", text: "stage.volunteer.reminder1".localized)
                reminderRow(icon: "figure.walk", text: "stage.volunteer.reminder2".localized)
                reminderRow(icon: "hand.raised", text: "stage.volunteer.reminder3".localized)
                reminderRow(icon: "eye", text: "stage.volunteer.reminder4".localized)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private func reminderRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.m) {
            Image(systemName: icon)
                .foregroundStyle(accentColor)
                .frame(width: 20)
            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Resources Card

    private var resourcesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "book.fill")
                    .foregroundStyle(accentColor)
                Text("av.volunteer.resources".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Button {
                showCrewInfo = true
                HapticManager.shared.lightTap()
            } label: {
                actionRow(
                    icon: "info.circle",
                    title: "stage.volunteer.crewInfo".localized,
                    color: accentColor
                )
            }
            .buttonStyle(.plain)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Action Row Helper

    private func actionRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
        }
        .padding(AppTheme.Spacing.m)
        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
    }
}

#Preview {
    StageVolunteerDeptView()
        .environmentObject(AppState.shared)
}

#Preview("Dark Mode") {
    StageVolunteerDeptView()
        .environmentObject(AppState.shared)
        .preferredColorScheme(.dark)
}
