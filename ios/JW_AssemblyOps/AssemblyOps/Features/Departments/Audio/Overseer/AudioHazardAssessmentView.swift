//
//  AudioHazardAssessmentView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - AV Hazard Assessment View
//
// Lists hazard assessments with type icons and PPE tags.
// Navigates to safety briefings. Supports create and swipe-to-delete.

import SwiftUI

struct AudioHazardAssessmentView: View {
    @StateObject private var viewModel = AudioSafetyViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showCreateHazard = false
    @State private var showError = false

    private var accentColor: Color {
        if let deptType = sessionState.selectedDepartment?.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Hazard Assessments section
                hazardsSection
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                // Safety Briefings link
                NavigationLink(destination: AudioSafetyBriefingsView()) {
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
            CreateHazardAssessmentSheet(viewModel: viewModel)
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

            // PPE tags
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

// MARK: - Flow Layout

/// Simple wrapping layout for PPE tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

#Preview {
    NavigationStack {
        AudioHazardAssessmentView()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        AudioHazardAssessmentView()
    }
    .preferredColorScheme(.dark)
}
