//
//  LostPersonAlertsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/16/26.
//

// MARK: - Lost Person Alerts View
//
// List of lost person alerts with resolved/unresolved filter.
// Shows person name, age, description, last seen details.
// Tap alert opens resolve sheet for overseer action.
//

import SwiftUI

struct LostPersonAlertsView: View {
    @StateObject private var viewModel = LostPersonViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var selectedAlert: LostPersonAlertItem?
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
                                await viewModel.loadAlerts(eventId: eventId)
                            }
                        }
                    }
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                if viewModel.isLoading && viewModel.alerts.isEmpty {
                    LoadingView(message: "attendant.lostPerson.title".localized)
                } else if viewModel.alerts.isEmpty {
                    emptyState
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                } else {
                    ForEach(Array(viewModel.alerts.enumerated()), id: \.element.id) { index, alert in
                        alertRow(alert)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05 + Double(index) * 0.03)
                    }
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("attendant.lostPerson.title".localized)
        .sheet(item: $selectedAlert) { alert in
            ResolveLostPersonSheet(alert: alert)
        }
        .refreshable {
            if let eventId = sessionState.selectedEvent?.id {
                await viewModel.loadAlerts(eventId: eventId)
            }
        }
        .task {
            if let eventId = sessionState.selectedEvent?.id {
                await viewModel.loadAlerts(eventId: eventId)
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

    // MARK: - Alert Row

    private func alertRow(_ alert: LostPersonAlertItem) -> some View {
        Button {
            if !alert.resolved {
                selectedAlert = alert
            }
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                HStack {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .foregroundStyle(alert.resolved ? AppTheme.StatusColors.accepted : AppTheme.StatusColors.declined)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(alert.personName)
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(.primary)
                        if let age = alert.age {
                            Text("\("attendant.lostPerson.age".localized): \(age)")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        }
                    }
                    Spacer()
                    if alert.resolved {
                        Text("attendant.incidents.resolved".localized)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.StatusColors.accepted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.StatusColors.acceptedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    } else {
                        Text("attendant.lostPerson.active".localized.uppercased())
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.StatusColors.declined)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.StatusColors.declinedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    }
                }

                Text(alert.description)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .lineLimit(3)

                VStack(spacing: AppTheme.Spacing.s) {
                    if let location = alert.lastSeenLocation {
                        HStack(spacing: AppTheme.Spacing.s) {
                            Image(systemName: "mappin")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            Text(location)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            Spacer()
                        }
                    }

                    HStack(spacing: AppTheme.Spacing.s) {
                        Image(systemName: "phone")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        Text(alert.contactName)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        if let phone = alert.contactPhone {
                            Link(phone, destination: URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))")!)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.themeColor)
                        }
                        Spacer()
                    }
                }

                HStack {
                    Text(alert.reportedByName)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Spacer()
                    Text(DateUtils.timeAgo(from: alert.createdAt))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                if let notes = alert.resolutionNotes {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("attendant.lostPerson.resolutionNotes".localized)
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
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Text("attendant.lostPerson.empty".localized)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxl)
    }

}

#Preview {
    NavigationStack {
        LostPersonAlertsView()
    }
}
