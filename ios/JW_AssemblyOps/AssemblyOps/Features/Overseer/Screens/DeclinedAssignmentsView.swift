//
//  DeclinedAssignmentsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/26/26.
//

// MARK: - Declined Assignments View
//
// Overseer view displaying assignments that volunteers have declined.
// Uses the app's design system with warm background and floating cards.
//
// Features:
//   - Warm gradient background
//   - Floating cards for each declined assignment
//   - Shows volunteer info, post, session, and decline reason
//   - Staggered entrance animations
//   - Pull-to-refresh for updated data
//   - Filters by department (if selected in OverseerSessionState)
//
// Components:
//   - emptyState: Styled empty state when no declines exist
//   - assignmentList: ScrollView with floating assignment cards
//   - DeclinedAssignmentRow: Individual assignment card with details
//
// Used by: AssignmentsView toolbar navigation

import SwiftUI

struct DeclinedAssignmentsView: View {
    @StateObject private var viewModel = DeclinedAssignmentsViewModel()
    @ObservedObject private var sessionState = OverseerSessionState.shared
    @Environment(\.colorScheme) var colorScheme

    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            // Warm background
            AppTheme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Loading declined assignments...")
                } else if viewModel.assignments.isEmpty {
                    emptyState
                } else {
                    assignmentList
                }
            }
        }
        .navigationTitle("Declined")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
        .task {
            await viewModel.load(
                eventId: sessionState.selectedEvent?.id,
                departmentId: sessionState.selectedDepartment?.id
            )
        }
        .onChange(of: sessionState.selectedDepartment) { _, _ in
            Task {
                await viewModel.load(
                    eventId: sessionState.selectedEvent?.id,
                    departmentId: sessionState.selectedDepartment?.id
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.StatusColors.acceptedBackground)
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.StatusColors.accepted)
            }

            Text("No Declined Assignments")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("All assignments have been accepted or are still pending")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppTheme.Spacing.screenEdge)
        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
    }

    // MARK: - Assignment List

    private var assignmentList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.m) {
                ForEach(Array(viewModel.assignments.enumerated()), id: \.element.id) { index, assignment in
                    DeclinedAssignmentRow(assignment: assignment, colorScheme: colorScheme)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.03)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

// MARK: - Declined Assignment Row

private struct DeclinedAssignmentRow: View {
    let assignment: DeclinedAssignment
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Header: Volunteer name and status
            HStack(alignment: .top) {
                // Avatar with initials
                ZStack {
                    Circle()
                        .fill(AppTheme.StatusColors.declinedBackground)
                        .frame(width: 44, height: 44)

                    Text(initials)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.StatusColors.declined)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(assignment.volunteerName)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)

                    Text(assignment.volunteerCongregation)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                // Status badge
                Text(assignment.status.displayName)
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(AppTheme.StatusColors.declined)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.StatusColors.declinedBackground)
                    .clipShape(Capsule())
            }

            // Divider
            Rectangle()
                .fill(AppTheme.dividerColor(for: colorScheme))
                .frame(height: 1)

            // Assignment details
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                detailRow(icon: "mappin.circle.fill", text: assignment.postName)
                detailRow(icon: "calendar", text: "\(assignment.sessionName) - \(assignment.date)")
                detailRow(icon: "clock.fill", text: "\(assignment.startTime) - \(assignment.endTime)")
            }

            // Decline reason (if provided)
            if let reason = assignment.declineReason, !reason.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack(spacing: 6) {
                        Image(systemName: "quote.bubble.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.StatusColors.declined)
                        Text("Reason")
                            .font(AppTheme.Typography.captionBold)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }

                    Text(reason)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(.primary)
                        .italic()
                        .padding(AppTheme.Spacing.s)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                }
            }

            // Declined timestamp
            if let respondedAt = assignment.respondedAt {
                Text("Declined \(relativeTimeString(from: respondedAt))")
                    .font(AppTheme.Typography.captionSmall)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Helpers

    private var initials: String {
        let names = assignment.volunteerName.split(separator: " ")
        if names.count >= 2 {
            return String(names[0].prefix(1) + names[1].prefix(1)).uppercased()
        }
        return String(assignment.volunteerName.prefix(2)).uppercased()
    }

    private func detailRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                .frame(width: 16)

            Text(text)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
    }

    private func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        DeclinedAssignmentsView()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        DeclinedAssignmentsView()
    }
    .preferredColorScheme(.dark)
}
