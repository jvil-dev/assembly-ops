//
//  VolunteerEventDiscoveryView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/24/26.
//

// MARK: - Volunteer Event Discovery View
//
// Shown to volunteers with no active EventVolunteer membership.
// Lists publicly visible events. Circuit Assembly → "Request to Join" button.
// Regional/Special Convention → "Invite Only" badge, no action.
//
// Data: discoverEvents query via VolunteerEventDiscoveryViewModel
//

import SwiftUI

struct VolunteerEventDiscoveryView: View {
    @StateObject private var viewModel = VolunteerEventDiscoveryViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                VStack(spacing: AppTheme.Spacing.xl) {
                    if !viewModel.sentRequestIds.isEmpty {
                        pendingRequestsBanner
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.08)
                    }

                    if viewModel.isLoading {
                        loadingSkeleton
                    } else if viewModel.events.isEmpty {
                        emptyState
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                    } else {
                        ForEach(Array(viewModel.events.enumerated()), id: \.element.id) { index, event in
                            eventCard(for: event)
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

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // Background canvas
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
                .frame(height: 220)

            // Decorative radial accent
            Circle()
                .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.18 : 0.07))
                .frame(width: 260, height: 260)
                .offset(x: 100, y: -30)
                .blur(radius: 60)

            VStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.25 : 0.12))
                        .frame(width: 72, height: 72)

                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(AppTheme.themeColor)
                }

                VStack(spacing: 6) {
                    Text("Find Your Event")
                        .font(.system(size: 26, weight: .bold, design: .default))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.1))

                    Text("Browse upcoming assemblies and request to serve.")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.bottom, AppTheme.Spacing.xxl)
            .padding(.horizontal, AppTheme.Spacing.screenEdge)
        }
    }

    // MARK: - Pending Requests Banner

    private var pendingRequestsBanner: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(AppTheme.themeColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.themeColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString("volunteer.eventDiscovery.pendingStatus.title", comment: ""))
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.1))

                Text(NSLocalizedString("volunteer.eventDiscovery.pendingStatus.subtitle", comment: ""))
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            Spacer()

            // Pulse dot
            Circle()
                .fill(AppTheme.themeColor)
                .frame(width: 8, height: 8)
        }
        .cardPadding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.15 : 0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .strokeBorder(AppTheme.themeColor.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Loading Skeleton

    private var loadingSkeleton: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ForEach(0..<3, id: \.self) { _ in
                skeletonCard
            }
        }
    }

    private var skeletonCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack {
                skeletonBar(width: 110, height: 12)
                Spacer()
            }
            skeletonBar(width: 200, height: 18)
            skeletonBar(width: 160, height: 14)
            skeletonBar(width: 130, height: 14)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .redacted(reason: .placeholder)
        .shimmering()
    }

    private func skeletonBar(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(AppTheme.textTertiary(for: colorScheme).opacity(0.3))
            .frame(width: width, height: height)
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
                Text("No Events Available")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                Text("Check back later or ask your department\noverseer for an invitation.")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }

            Button {
                viewModel.loadEvents()
            } label: {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                    Text("Refresh")
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
        .frame(maxWidth: .infinity)
    }

    // MARK: - Event Card

    @ViewBuilder
    private func eventCard(for event: DiscoverableEvent) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top strip — event type label + invite badge
            HStack {
                EventTypePill(type: event.displayEventType, themeColor: AppTheme.themeColor, colorScheme: colorScheme)
                Spacer()
                if event.isInviteOnly {
                    inviteOnlyBadge
                }
            }
            .padding(.horizontal, AppTheme.Spacing.cardPadding)
            .padding(.top, AppTheme.Spacing.cardPadding)
            .padding(.bottom, AppTheme.Spacing.m)

            // Divider under header strip
            Rectangle()
                .fill(AppTheme.dividerColor(for: colorScheme))
                .frame(height: 1)
                .padding(.horizontal, AppTheme.Spacing.cardPadding)

            // Body
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                Text(event.name)
                    .font(.system(size: 20, weight: .semibold, design: .default))
                    .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.1))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                    metaRow(icon: "mappin.circle.fill", text: event.venue)
                    metaRow(icon: "calendar", text: Self.formatDateRange(event.startDate, event.endDate))
                    metaRow(icon: "person.2.fill", text: "\(event.volunteerCount) volunteers serving")
                }
            }
            .padding(.horizontal, AppTheme.Spacing.cardPadding)
            .padding(.top, AppTheme.Spacing.m)
            .padding(.bottom, event.isInviteOnly ? AppTheme.Spacing.cardPadding : AppTheme.Spacing.m)

            // Action footer
            if !event.isInviteOnly {
                Rectangle()
                    .fill(AppTheme.dividerColor(for: colorScheme))
                    .frame(height: 1)
                    .padding(.horizontal, AppTheme.Spacing.cardPadding)

                joinButtonRow(for: event)
                    .padding(.horizontal, AppTheme.Spacing.cardPadding)
                    .padding(.vertical, AppTheme.Spacing.m)
            }
        }
        .themedCard(scheme: colorScheme)
    }

    private func metaRow(icon: String, text: String) -> some View {
        HStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.themeColor.opacity(0.7))
                .frame(width: 18)
            Text(text)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
    }

    // MARK: - Invite Only Badge

    private var inviteOnlyBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: 9))
            Text(NSLocalizedString("volunteer.eventDiscovery.inviteOnly", comment: ""))
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(AppTheme.textTertiary(for: colorScheme).opacity(0.12))
        )
        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
    }

    // MARK: - Join Button Row

    @ViewBuilder
    private func joinButtonRow(for event: DiscoverableEvent) -> some View {
        let isRequesting = viewModel.pendingRequestIds.contains(event.id)
        let hasSent = viewModel.sentRequestIds.contains(event.id)

        if hasSent {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.StatusColors.accepted)
                Text(NSLocalizedString("volunteer.eventDiscovery.requestSent", comment: ""))
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundStyle(AppTheme.StatusColors.accepted)
                Spacer()
            }
            .padding(.vertical, AppTheme.Spacing.xs)
        } else {
            Button {
                viewModel.requestToJoin(eventId: event.id)
            } label: {
                HStack(spacing: AppTheme.Spacing.s) {
                    if isRequesting {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14))
                        Text(NSLocalizedString("volunteer.eventDiscovery.requestToJoin", comment: ""))
                            .font(AppTheme.Typography.bodyMedium)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.ButtonHeight.medium)
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .fill(isRequesting
                          ? AppTheme.themeColor.opacity(0.6)
                          : AppTheme.themeColor)
            )
            .foregroundStyle(.white)
            .disabled(isRequesting)
            .animation(AppTheme.quickAnimation, value: isRequesting)
        }
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

// MARK: - Event Type Pill

private struct EventTypePill: View {
    let type: String
    let themeColor: Color
    let colorScheme: ColorScheme

    var body: some View {
        Text(type.uppercased())
            .font(.system(size: 10, weight: .bold, design: .default))
            .tracking(0.8)
            .padding(.horizontal, AppTheme.Spacing.m)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(themeColor.opacity(colorScheme == .dark ? 0.25 : 0.1))
            )
            .foregroundStyle(themeColor)
    }
}

// MARK: - Shimmer Modifier (skeleton loading)

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.35), location: 0.4),
                            .init(color: .clear, location: 0.8)
                        ],
                        startPoint: .init(x: phase, y: 0.5),
                        endPoint: .init(x: phase + 0.6, y: 0.5)
                    )
                    .blendMode(.plusLighter)
                }
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.4)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1.4
                }
            }
    }
}

private extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

#Preview {
    VolunteerEventDiscoveryView()
}
