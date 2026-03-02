//
//  VideoVolunteerDeptView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Video Volunteer Department View
//
// Hub for Video crew volunteers. Shows quick actions, active equipment
// checkouts, safety briefings, shot guidelines, and crew info.
//
// Used by: DepartmentTabRouter (for VIDEO volunteers)

import SwiftUI

struct VideoVolunteerDeptView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = VideoVolunteerViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showReportDamage = false
    @State private var showWalkThrough = false
    @State private var showCrewInfo = false
    @State private var showShotGuidelines = false
    @State private var showError = false

    private let accentColor = DepartmentColor.color(for: "VIDEO")

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                quickActionsCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                myEquipmentCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                myBriefingsCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.10)

                resourcesCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("video.dashboard.title".localized)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showReportDamage) {
            ReportVideoDamageView(equipment: viewModel.equipment)
        }
        .sheet(isPresented: $showWalkThrough) {
            VideoWalkThroughChecklistView(isOverseer: false)
        }
        .sheet(isPresented: $showCrewInfo) {
            VideoCrewInfoView()
        }
        .sheet(isPresented: $showShotGuidelines) {
            VideoShotGuidelinesSheet()
        }
        .onChange(of: viewModel.error) { _, error in
            showError = error != nil
        }
        .alert("common.error".localized, isPresented: $showError) {
            Button("common.ok".localized) { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
        .task {
            if let eventId = appState.currentEventId {
                await viewModel.loadVolunteerData(eventId: eventId)
            }
        }
    }

    // MARK: - Quick Actions Card

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(accentColor)
                Text("av.volunteer.quickActions".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Button {
                showReportDamage = true
                HapticManager.shared.lightTap()
            } label: {
                actionRow(icon: "exclamationmark.triangle", title: "av.volunteer.reportDamage".localized, color: .orange)
            }
            .buttonStyle(.plain)

            if viewModel.hasMediaAssignment {
                Button {
                    showWalkThrough = true
                    HapticManager.shared.lightTap()
                } label: {
                    actionRow(icon: "checklist", title: "av.volunteer.walkThrough".localized, color: .blue)
                }
                .buttonStyle(.plain)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - My Equipment Card

    private var myEquipmentCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "video.badge.checkmark")
                    .foregroundStyle(accentColor)
                Text("av.volunteer.myEquipment".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            if viewModel.activeCheckouts.isEmpty {
                Text("av.volunteer.noCheckouts".localized)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            } else {
                ForEach(viewModel.activeCheckouts) { checkout in
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(checkout.equipmentName ?? "")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(.primary)
                            Text(checkout.checkedOutAt.formatted(date: .abbreviated, time: .shortened))
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }
                        Spacer()
                        if let cat = checkout.equipmentCategory {
                            Image(systemName: cat.icon)
                                .foregroundStyle(accentColor)
                        }
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - My Briefings Card

    private var myBriefingsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "person.3.sequence")
                    .foregroundStyle(accentColor)
                Text("av.volunteer.myBriefings".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            if viewModel.myBriefings.isEmpty {
                Text("av.volunteer.noBriefings".localized)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            } else {
                ForEach(viewModel.myBriefings) { briefing in
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(briefing.topic)
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(.primary)
                            Text(briefing.conductedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }
                        Spacer()
                        Text(briefing.conductedByName)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Resources Card (Video-specific: crew info + shot guidelines)

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
                actionRow(icon: "info.circle", title: "video.volunteer.crewInfo".localized, color: accentColor)
            }
            .buttonStyle(.plain)

            Button {
                showShotGuidelines = true
                HapticManager.shared.lightTap()
            } label: {
                actionRow(icon: "camera.viewfinder", title: "video.volunteer.shotGuidelines".localized, color: accentColor)
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
    VideoVolunteerDeptView()
        .environmentObject(AppState.shared)
}

#Preview("Dark Mode") {
    VideoVolunteerDeptView()
        .environmentObject(AppState.shared)
        .preferredColorScheme(.dark)
}
