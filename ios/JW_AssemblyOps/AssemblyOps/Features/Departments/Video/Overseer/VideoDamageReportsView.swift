//
//  VideoDamageReportsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Video Damage Reports View
//
// List of damage reports for video equipment.
// Resolved/unresolved toggle. Tap to resolve via ResolveVideoDamageSheet.

import SwiftUI

struct VideoDamageReportsView: View {
    @StateObject private var viewModel = VideoDamageViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var selectedReport: AudioDamageReportItem?
    @State private var showResolve = false
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Filter toggle
                HStack {
                    Text("av.damage.title".localized)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Toggle("av.damage.showResolved".localized, isOn: $viewModel.showResolved)
                        .toggleStyle(.switch)
                        .labelsHidden()
                    Text("av.damage.showResolved".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.filteredReports.isEmpty {
                    VStack(spacing: AppTheme.Spacing.m) {
                        Image(systemName: "checkmark.seal")
                            .font(.system(size: 40))
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        Text("av.damage.empty".localized)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.xxl)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                } else {
                    LazyVStack(spacing: AppTheme.Spacing.m) {
                        ForEach(Array(viewModel.filteredReports.enumerated()), id: \.element.id) { index, report in
                            damageRow(report)
                                .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.02 + 0.05)
                        }
                    }
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("av.damage.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showResolve) {
            if let report = selectedReport {
                ResolveVideoDamageSheet(report: report, viewModel: viewModel)
            }
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
                await viewModel.loadReports(eventId: eventId)
            }
        }
        .task {
            if let eventId = sessionState.selectedEvent?.id {
                await viewModel.loadReports(eventId: eventId)
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Damage Row

    private func damageRow(_ report: AudioDamageReportItem) -> some View {
        Button {
            if !report.resolved {
                selectedReport = report
                showResolve = true
                HapticManager.shared.lightTap()
            }
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                HStack {
                    Image(systemName: report.equipmentCategory?.icon ?? "video")
                        .foregroundStyle(report.severity.color)
                    Text(report.equipmentName)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(report.severity.displayName)
                        .font(AppTheme.Typography.captionSmall).fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(report.severity.color.opacity(0.12))
                        .foregroundStyle(report.severity.color)
                        .clipShape(Capsule())
                }

                Text(report.description)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .lineLimit(2)

                HStack {
                    Text(report.reportedByName)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Spacer()
                    if report.resolved {
                        Label("av.damage.resolved".localized, systemImage: "checkmark.circle.fill")
                            .font(AppTheme.Typography.captionSmall).fontWeight(.medium)
                            .foregroundStyle(.green)
                    } else {
                        Text("av.damage.tapToResolve".localized)
                            .font(AppTheme.Typography.captionSmall)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                }
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        VideoDamageReportsView()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        VideoDamageReportsView()
    }
    .preferredColorScheme(.dark)
}
