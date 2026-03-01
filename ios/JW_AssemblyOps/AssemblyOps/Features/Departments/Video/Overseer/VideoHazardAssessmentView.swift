//
//  VideoHazardAssessmentView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Video Hazard Assessment View
//
// Lists hazard assessments for the video crew with type icons and PPE tags.
// Includes link to VideoSafetyBriefingsView. Supports create and delete.

import SwiftUI

struct VideoHazardAssessmentView: View {
    @StateObject private var viewModel = VideoSafetyViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showCreateHazard = false
    @State private var showError = false

    private let accentColor = DepartmentColor.color(for: "VIDEO")

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                hazardsSection
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                NavigationLink(destination: VideoSafetyBriefingsView()) {
                    briefingsLinkCard
                }
                .buttonStyle(.plain)
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("av.safety.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateHazard = true
                    HapticManager.shared.lightTap()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateHazard) {
            CreateVideoHazardAssessmentSheet(viewModel: viewModel)
        }
        .onChange(of: viewModel.error) { _, error in
            showError = error != nil
        }
        .alert("common.error".localized, isPresented: $showError) {
            Button("common.ok".localized) { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .refreshable {
            if let eventId = sessionState.selectedEvent?.id {
                await viewModel.loadAll(eventId: eventId)
            }
        }
        .task {
            if let eventId = sessionState.selectedEvent?.id {
                await viewModel.loadAll(eventId: eventId)
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Hazards Section

    private var hazardsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "shield.checkered")
                    .foregroundStyle(accentColor)
                Text("av.hazard.title".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if viewModel.hazardAssessments.isEmpty {
                Text("av.hazard.empty".localized)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(viewModel.hazardAssessments) { hazard in
                    hazardRow(hazard)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private func hazardRow(_ hazard: AudioHazardAssessmentItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            HStack {
                Image(systemName: hazard.hazardType.icon)
                    .foregroundStyle(.orange)
                Text(hazard.title)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Button(role: .destructive) {
                    Task {
                        _ = await viewModel.deleteHazardAssessment(id: hazard.id)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
            }

            Text(hazard.description)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .lineLimit(2)

            if !hazard.ppeRequired.isEmpty {
                FlowLayout(spacing: AppTheme.Spacing.xs) {
                    ForEach(hazard.ppeRequired, id: \.self) { ppe in
                        if let ppeType = AudioPPEType(rawValue: ppe) {
                            Label(ppeType.displayName, systemImage: ppeType.icon)
                                .font(AppTheme.Typography.captionSmall)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(accentColor.opacity(0.1))
                                .foregroundStyle(accentColor)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            HStack {
                Text(hazard.completedByName)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                Spacer()
                Text(hazard.completedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
        }
        .padding(.vertical, AppTheme.Spacing.s)
    }

    // MARK: - Briefings Link Card

    private var briefingsLinkCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "person.3.sequence")
                    .foregroundStyle(accentColor)
                Text("av.safety.briefings".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            HStack {
                Text(String(format: "av.safety.briefingsCount".localized, viewModel.safetyBriefings.count))
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }
}

#Preview {
    NavigationStack {
        VideoHazardAssessmentView()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        VideoHazardAssessmentView()
    }
    .preferredColorScheme(.dark)
}
