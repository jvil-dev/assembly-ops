//
//  AssignmentDetailView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Assignment Detail View
//
// Full-screen detail view for a single assignment.
// Uses the app's design system with warm background and floating cards.
//
// Features:
//   - Warm gradient background
//   - Floating header card with post info
//   - Detailed info section with icons
//   - Accept/Decline buttons for pending assignments (iOS 26 glass effect)
//   - Check-in controls for accepted assignments
//   - Captain group roster (if applicable)
//   - Staggered entrance animations
//

import SwiftUI

struct AssignmentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: AssignmentDetailViewModel

    let assignment: Assignment
    let onUpdate: () -> Void

    @State private var showDeclineSheet = false
    @State private var declineReason = ""
    @State private var hasAppeared = false

    init(assignment: Assignment, onUpdate: @escaping () -> Void = {}) {
        self.assignment = assignment
        self.onUpdate = onUpdate
        _viewModel = StateObject(wrappedValue: AssignmentDetailViewModel(assignment: assignment))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Header card
                headerCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                // Details card
                detailsCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                // Accept/Decline for pending
                if assignment.canRespond {
                    acceptDeclineSection
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                }

                // Check-in for accepted
                if assignment.isAccepted {
                    checkInCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                }

                // Captain group (if captain)
                if assignment.isCaptain && assignment.isAccepted {
                    captainGroupCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("Assignment")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
        .sheet(isPresented: $showDeclineSheet) {
            DeclineReasonSheet(reason: $declineReason) {
                Task {
                    await viewModel.declineAssignment(reason: declineReason.isEmpty ? nil : declineReason)
                    onUpdate()
                    dismiss()
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Post name and status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(assignment.postName)
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(.primary)

                    // Department with color
                    HStack(spacing: 6) {
                        Circle()
                            .fill(assignment.departmentColor)
                            .frame(width: 10, height: 10)
                        Text(assignment.departmentName)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                }

                Spacer()

                AssignmentStatusBadge(
                    status: assignment.status,
                    isCaptain: assignment.isCaptain
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
            Text("Details")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.themeColor)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                DetailRow(
                    icon: "calendar",
                    title: "Date",
                    value: assignment.date.formatted(date: .complete, time: .omitted),
                    colorScheme: colorScheme
                )

                DetailRow(
                    icon: "clock",
                    title: "Time",
                    value: assignment.timeRangeFormatted,
                    colorScheme: colorScheme
                )

                if let location = assignment.postLocation {
                    DetailRow(
                        icon: "mappin",
                        title: "Location",
                        value: location,
                        colorScheme: colorScheme
                    )
                }

                DetailRow(
                    icon: "person.2",
                    title: "Session",
                    value: assignment.sessionName,
                    colorScheme: colorScheme
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Accept/Decline Section

    private var acceptDeclineSection: some View {
        AcceptDeclineButtons(
            assignment: assignment,
            onAccept: {
                Task {
                    await viewModel.acceptAssignment()
                    onUpdate()
                    dismiss()
                }
            },
            onDecline: {
                showDeclineSheet = true
            }
        )
    }

    // MARK: - Check-in Card

    private var checkInCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            Text("Attendance")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.themeColor)

            CheckInButton(
                assignment: assignment,
                onCheckIn: {
                    Task {
                        await viewModel.checkIn()
                        onUpdate()
                    }
                },
                onCheckOut: {
                    Task {
                        await viewModel.checkOut()
                        onUpdate()
                    }
                }
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Captain Group Card

    private var captainGroupCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Your Group")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.themeColor)
            }

            CaptainGroupView(
                postId: assignment.postId,
                sessionId: assignment.sessionId,
                onCheckIn: onUpdate
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }
}

// MARK: - Detail Row

private struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.themeColor)
                .frame(width: 24, height: 24)

            // Title
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .frame(width: 70, alignment: .leading)

            // Value
            Text(value)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        AssignmentDetailView(assignment: .preview)
    }
}

#Preview("Pending") {
    NavigationStack {
        AssignmentDetailView(assignment: .previewPending)
    }
}

#Preview("Captain") {
    NavigationStack {
        AssignmentDetailView(assignment: .previewCaptain)
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        AssignmentDetailView(assignment: .previewPending)
    }
    .preferredColorScheme(.dark)
}
