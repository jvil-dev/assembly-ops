//
//  LanyardGridView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/1/26.
//

// MARK: - Lanyard Grid View
//
// Overseer view showing all volunteers' lanyard status for today.
// Color-coded: gray (not picked up), green (picked up), blue (returned).
// Overseer can tap to mark pickup/return on behalf of a volunteer.
// Includes search/filter by name.
//

import SwiftUI

struct LanyardGridView: View {
    @StateObject private var viewModel = LanyardViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var searchText = ""

    private var accentColor: Color {
        if let deptType = sessionState.selectedDepartment?.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    private var eventId: String? {
        sessionState.selectedEvent?.id
    }

    private var filteredStatuses: [LanyardStatusItem] {
        if searchText.isEmpty {
            return viewModel.allStatuses
        }
        return viewModel.allStatuses.filter {
            $0.volunteerName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.allStatuses.isEmpty {
                LoadingView(message: "lanyard.grid.title".localized)
                    .themedBackground(scheme: colorScheme)
            } else {
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        if let summary = viewModel.summary {
                            summaryCard(summary)
                                .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                        }

                        volunteerList
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                    }
                    .screenPadding()
                    .padding(.top, AppTheme.Spacing.l)
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }
                .themedBackground(scheme: colorScheme)
                .refreshable {
                    if let eventId = eventId {
                        await viewModel.loadAllStatuses(eventId: eventId)
                    }
                }
            }
        }
        .navigationTitle("lanyard.grid.title".localized)
        .searchable(text: $searchText, prompt: "lanyard.grid.search".localized)
        .task {
            if let eventId = eventId {
                await viewModel.loadAllStatuses(eventId: eventId)
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Summary Card

    private func summaryCard(_ summary: LanyardSummaryItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "chart.bar", title: "lanyard.grid.summary".localized)

            HStack(spacing: AppTheme.Spacing.l) {
                summaryPill(count: summary.notPickedUp, label: "lanyard.grid.notPickedUp".localized, color: AppTheme.textTertiary(for: colorScheme))
                summaryPill(count: summary.pickedUp, label: "lanyard.grid.pickedUp".localized, color: AppTheme.StatusColors.accepted)
                summaryPill(count: summary.returned, label: "lanyard.grid.returned".localized, color: AppTheme.StatusColors.info)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private func summaryPill(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text("\(count)")
                .font(AppTheme.Typography.title)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Volunteer List

    private var volunteerList: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack {
                SectionHeaderLabel(icon: "person.3", title: "lanyard.grid.volunteers".localized)
                Spacer()
                Text("\(filteredStatuses.count)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            if filteredStatuses.isEmpty {
                Text("lanyard.grid.noVolunteers".localized)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.l)
            } else {
                ForEach(filteredStatuses) { status in
                    volunteerRow(status)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private func volunteerRow(_ status: LanyardStatusItem) -> some View {
        HStack(spacing: AppTheme.Spacing.m) {
            statusIndicator(status.status)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(status.volunteerName)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundStyle(.primary)
                Text(statusText(status.status))
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            Spacer()

            // Overseer action button
            overseerActionButton(for: status)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }

    private func statusIndicator(_ state: LanyardState) -> some View {
        Circle()
            .fill(statusColor(state))
            .frame(width: 12, height: 12)
    }

    private func statusColor(_ state: LanyardState) -> Color {
        switch state {
        case .notPickedUp: return AppTheme.textTertiary(for: colorScheme)
        case .pickedUp: return AppTheme.StatusColors.accepted
        case .returned: return AppTheme.StatusColors.info
        }
    }

    private func statusText(_ state: LanyardState) -> String {
        switch state {
        case .notPickedUp: return "lanyard.status.notPickedUp".localized
        case .pickedUp: return "lanyard.status.pickedUp".localized
        case .returned: return "lanyard.status.returned".localized
        }
    }

    @ViewBuilder
    private func overseerActionButton(for status: LanyardStatusItem) -> some View {
        switch status.status {
        case .notPickedUp:
            Button {
                guard let eventId = eventId else { return }
                Task {
                    await viewModel.overseerPickUp(eventVolunteerId: status.eventVolunteerId, eventId: eventId)
                }
            } label: {
                Text("lanyard.pickUp".localized)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(AppTheme.StatusColors.accepted.opacity(0.12))
                    .foregroundStyle(AppTheme.StatusColors.accepted)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

        case .pickedUp:
            Button {
                guard let eventId = eventId else { return }
                Task {
                    await viewModel.overseerReturn(eventVolunteerId: status.eventVolunteerId, eventId: eventId)
                }
            } label: {
                Text("lanyard.return".localized)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(AppTheme.StatusColors.info.opacity(0.12))
                    .foregroundStyle(AppTheme.StatusColors.info)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

        case .returned:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.StatusColors.info)
        }
    }
}

#Preview {
    NavigationStack {
        LanyardGridView()
    }
}
