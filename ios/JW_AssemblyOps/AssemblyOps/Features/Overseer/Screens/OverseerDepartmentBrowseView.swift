//
//  OverseerDepartmentBrowseView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/26/26.
//

// MARK: - Overseer Department Browse View
//
// Shows public events list for overseers to select and purchase a department.
// Tap event → push DepartmentSelectionView.
// Embedded inside EventsHomeView NavigationStack (no inner NavigationStack).
//

import SwiftUI

struct OverseerDepartmentBrowseView: View {
    @StateObject private var viewModel = OverseerDepartmentBrowseViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                VStack(spacing: AppTheme.Spacing.xl) {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, AppTheme.Spacing.xxl)
                    } else if viewModel.events.isEmpty {
                        emptyState
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                    } else {
                        ForEach(Array(viewModel.events.enumerated()), id: \.element.id) { index, event in
                            NavigationLink(value: event) {
                                eventCard(for: event)
                            }
                            .buttonStyle(.plain)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.06 + 0.1)
                        }
                    }
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.xl)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
        }
        .themedBackground(scheme: colorScheme)
        .refreshable { viewModel.loadEvents() }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) { hasAppeared = true }
            viewModel.loadEvents()
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

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.themeColor.opacity(colorScheme == .dark ? 0.45 : 0.12),
                            AppTheme.themeColor.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 200)

            VStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.25 : 0.12))
                        .frame(width: 72, height: 72)
                    Image(systemName: "building.2.crop.circle")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(AppTheme.themeColor)
                }

                VStack(spacing: 6) {
                    Text("browseEvents.overseer.title".localized)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.1))

                    Text("browseEvents.overseer.subtitle".localized)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.bottom, AppTheme.Spacing.xxl)
            .padding(.horizontal, AppTheme.Spacing.screenEdge)
        }
    }

    // MARK: - Event Card

    private func eventCard(for event: DiscoverableEvent) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack {
                Text(event.displayEventType.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(Capsule().fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.25 : 0.1)))
                    .foregroundStyle(AppTheme.themeColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text(event.name)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.themeColor.opacity(0.7))
                        .frame(width: 18)
                    Text(event.venue)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.themeColor.opacity(0.7))
                        .frame(width: 18)
                    Text(Self.formatDateRange(event.startDate, event.endDate))
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(AppTheme.textTertiary(for: colorScheme).opacity(0.08))
                    .frame(width: 96, height: 96)
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            VStack(spacing: AppTheme.Spacing.s) {
                Text("browseEvents.empty.title".localized)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                Text("browseEvents.empty.subtitle".localized)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }

            Button {
                viewModel.loadEvents()
            } label: {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "arrow.clockwise")
                    Text("common.retry".localized)
                        .font(AppTheme.Typography.bodyMedium)
                }
                .frame(height: AppTheme.ButtonHeight.medium)
                .padding(.horizontal, AppTheme.Spacing.xxl)
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .stroke(AppTheme.themeColor, lineWidth: 1.5)
            )
            .foregroundStyle(AppTheme.themeColor)
        }
        .padding(.top, AppTheme.Spacing.xxl)
    }

    // MARK: - Helpers

    private static func formatDateRange(_ start: String, _ end: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, yyyy"
        let startStr = DateUtils.parseISO8601(start).map { fmt.string(from: $0) } ?? start
        let endStr = DateUtils.parseISO8601(end).map { fmt.string(from: $0) } ?? end
        return "\(startStr) – \(endStr)"
    }
}
