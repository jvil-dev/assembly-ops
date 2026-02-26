//
//  ArchivedEventsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/25/26.
//

// MARK: - Archived Events View
//
// Shows events that ended more than 30 days ago.
// Pushed from SettingsView as a NavigationLink.
// Events displayed as view-only cards (dimmed, non-interactive).

import SwiftUI

struct ArchivedEventsView: View {
    @StateObject private var viewModel = ArchivedEventsViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, AppTheme.Spacing.xxl)
                } else if viewModel.archivedEvents.isEmpty {
                    emptyState
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                } else {
                    ForEach(Array(viewModel.archivedEvents.enumerated()), id: \.element.id) { index, event in
                        archivedEventCard(event)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.05)
                    }
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .refreshable { await viewModel.reload() }
        .navigationTitle("settings.archivedEvents".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) { hasAppeared = true }
            viewModel.loadArchivedEvents()
        }
        .onChange(of: viewModel.errorMessage) { _, error in
            showError = error != nil
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Archived Event Card

    private func archivedEventCard(_ event: ArchivedEventsViewModel.ArchivedEventItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack {
                Text(event.displayEventType.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(Capsule().fill(AppTheme.textTertiary(for: colorScheme).opacity(0.12)))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

                Spacer()

                Image(systemName: "archivebox.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text(event.eventName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "person.badge.shield.checkmark")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        .frame(width: 18)
                    Text(event.displayRole)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        .frame(width: 18)
                    Text(event.venue)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        .frame(width: 18)
                    Text(event.dateRangeString)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .opacity(0.7)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(AppTheme.textTertiary(for: colorScheme).opacity(0.08))
                    .frame(width: 96, height: 96)
                Image(systemName: "archivebox")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            VStack(spacing: AppTheme.Spacing.s) {
                Text("archivedEvents.empty.title".localized)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                Text("archivedEvents.empty.subtitle".localized)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, AppTheme.Spacing.xxl)
        .frame(maxWidth: .infinity)
    }
}
