//
//  StageDashboardView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Stage Dashboard View
//
// Overseer dashboard for the Stage department (CO-160 Ch. 3).
// Cards: Participant Reminders status, Stage Configuration,
// Makeup Coordination, Walk-Throughs, Volunteers, Settings.
//
// Note: No equipment/damage/hazard cards — Stage crew doesn't manage AV equipment.

import SwiftUI

struct StageDashboardView: View {
    @StateObject private var viewModel = StageDashboardViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showError = false

    private let accentColor = DepartmentColor.color(for: "STAGE")

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // 1. Walk-Throughs
                NavigationLink(destination: StageWalkThroughView()) {
                    dashboardCard(
                        icon: "checklist",
                        title: "stage.dashboard.walkThroughs".localized,
                        subtitle: String(format: "stage.dashboard.walkThroughsCount".localized, viewModel.walkThroughCount),
                        color: accentColor
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                // 2. Stage Configuration
                NavigationLink(destination: StageConfigurationView()) {
                    dashboardCard(
                        icon: "square.3.layers.3d",
                        title: "stage.dashboard.stageConfig".localized,
                        subtitle: "stage.dashboard.stageConfigSub".localized,
                        color: accentColor
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                // 3. Makeup Coordination
                NavigationLink(destination: MakeupStatusView()) {
                    dashboardCard(
                        icon: "sparkles",
                        title: "stage.dashboard.makeup".localized,
                        subtitle: "stage.dashboard.makeupSub".localized,
                        color: accentColor
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.10)

                // 4. Volunteers
                NavigationLink(destination: VolunteerListView()) {
                    dashboardCard(
                        icon: "person.2.fill",
                        title: "av.dashboard.volunteers".localized,
                        subtitle: "av.dashboard.volunteersDesc".localized,
                        color: accentColor
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)

                // 5. Settings
                NavigationLink(destination: DepartmentSettingsView(departmentId: sessionState.selectedDepartment?.id ?? "")) {
                    dashboardCard(
                        icon: "gearshape.fill",
                        title: "av.dashboard.settings".localized,
                        subtitle: "av.dashboard.settingsDesc".localized,
                        color: .gray
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.20)
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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
                await viewModel.loadDashboard(eventId: eventId)
            }
        }
        .task {
            if let eventId = sessionState.selectedEvent?.id {
                await viewModel.loadDashboard(eventId: eventId)
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Dashboard Card

    private func dashboardCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: AppTheme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                Text(subtitle)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.primary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }
}

// MARK: - Stage Walk-Through View (Overseer)

/// Stage walk-through checklist using the stageSetup checklist type.
struct StageWalkThroughView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var checklistItems: [AudioChecklistItem] = stageSetupItems

    private let accentColor = DepartmentColor.color(for: "STAGE")

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                Text(StageChecklistType.stageSetup.subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                VStack(spacing: AppTheme.Spacing.s) {
                    ForEach(Array(checklistItems.enumerated()), id: \.element.id) { index, item in
                        Button {
                            checklistItems[index].isChecked.toggle()
                            HapticManager.shared.lightTap()
                        } label: {
                            HStack(spacing: AppTheme.Spacing.m) {
                                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(item.isChecked ? .green : AppTheme.textTertiary(for: colorScheme))
                                    .font(.system(size: 20))

                                Text(item.displayText)
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(item.isChecked ? AppTheme.textSecondary(for: colorScheme) : .primary)
                                    .strikethrough(item.isChecked)
                                    .multilineTextAlignment(.leading)

                                Spacer()
                            }
                            .padding(AppTheme.Spacing.m)
                            .background(AppTheme.cardBackground(for: colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.03 + 0.05)
                    }
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("stage.dashboard.walkThroughs".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }
}

#Preview {
    StageDashboardView()
}

#Preview("Dark Mode") {
    StageDashboardView()
        .preferredColorScheme(.dark)
}
