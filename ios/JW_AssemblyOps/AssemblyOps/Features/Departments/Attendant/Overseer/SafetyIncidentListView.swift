//
//  SafetyIncidentListView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/16/26.
//

// MARK: - Safety Incident List View
//
// List of safety incidents with resolved/unresolved filter.
// Tap incident opens resolve sheet for overseer action.
//

import SwiftUI

struct SafetyIncidentListView: View {
    @StateObject private var viewModel = SafetyIncidentViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var selectedIncident: SafetyIncidentItem?
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Filter toggle
                Toggle("attendant.incidents.showResolved".localized, isOn: $viewModel.showResolved)
                    .font(AppTheme.Typography.subheadline)
                    .tint(AppTheme.themeColor)
                    .cardPadding()
                    .themedCard(scheme: colorScheme)
                    .onChange(of: viewModel.showResolved) { _, _ in
                        Task {
                            if let eventId = sessionState.selectedEvent?.id {
                                await viewModel.loadIncidents(eventId: eventId)
                            }
                        }
                    }
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                if viewModel.isLoading && viewModel.incidents.isEmpty {
                    LoadingView(message: "attendant.incidents.title".localized)
                } else if viewModel.incidents.isEmpty {
                    emptyState
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                } else {
                    ForEach(Array(viewModel.incidents.enumerated()), id: \.element.id) { index, incident in
                        incidentRow(incident)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05 + Double(index) * 0.03)
                    }
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("attendant.incidents.title".localized)
        .sheet(item: $selectedIncident) { incident in
            ResolveIncidentSheet(incident: incident)
        }
        .refreshable {
            if let eventId = sessionState.selectedEvent?.id {
                await viewModel.loadIncidents(eventId: eventId)
            }
        }
        .task {
            if let eventId = sessionState.selectedEvent?.id {
                await viewModel.loadIncidents(eventId: eventId)
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
        .onChange(of: viewModel.error) { _, newValue in showError = newValue != nil }
        .alert("common.error".localized, isPresented: $showError) {
            Button("common.ok".localized) { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    // MARK: - Incident Row

    private func incidentRow(_ incident: SafetyIncidentItem) -> some View {
        Button {
            if !incident.resolved {
                selectedIncident = incident
            }
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                HStack {
                    Image(systemName: incident.type.icon)
                        .foregroundStyle(incident.resolved ? AppTheme.StatusColors.accepted : AppTheme.StatusColors.warning)
                    Text(incident.type.displayName)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    if incident.resolved {
                        Text("attendant.incidents.resolved".localized)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.StatusColors.accepted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.StatusColors.acceptedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    }
                }

                Text(incident.description)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .lineLimit(3)

                HStack(spacing: AppTheme.Spacing.l) {
                    if let location = incident.location {
                        Label(location, systemImage: "mappin")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                    if let postName = incident.postName {
                        Label(postName, systemImage: "map")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                }

                HStack {
                    Text(incident.reportedByName)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Spacer()
                    Text(DateUtils.timeAgo(from: incident.createdAt))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                if let notes = incident.resolutionNotes {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("attendant.incidents.notes".localized)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        Text(notes)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                    .padding(AppTheme.Spacing.s)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                }
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Text("attendant.incidents.empty".localized)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxl)
    }

}

#Preview {
    NavigationStack {
        SafetyIncidentListView()
    }
}
