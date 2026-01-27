//
//  SlotDetailSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Slot Detail Sheet
//
// Modal view showing details for a coverage matrix slot (post + session).
// Uses the app's design system with warm background and floating cards.
//
// Sections:
//   - Slot Info: Post name, session name, coverage count
//   - Assigned Volunteers: List of current assignments with check-in status
//   - Add Volunteer: Styled button (if not at capacity)
//
// Features:
//   - Warm gradient background
//   - Floating cards with themed styling
//   - Entrance animations
//

import SwiftUI

struct SlotDetailSheet: View {
    let slot: CoverageSlot
    @ObservedObject var viewModel: CoverageMatrixViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var showVolunteerPicker = false
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Slot info card
                    slotInfoCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Assigned volunteers card
                    volunteersCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // Add volunteer button
                    if slot.filled < slot.capacity {
                        addVolunteerButton
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                    }
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("Slot Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showVolunteerPicker) {
                VolunteerPickerSheet(
                    postId: slot.postId,
                    sessionId: slot.sessionId
                ) { success in
                    if success {
                        Task {
                            await viewModel.loadCoverage()
                        }
                    }
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Slot Info Card

    private var slotInfoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "tablecells")
                    .foregroundStyle(AppTheme.themeColor)
                Text("Slot Information")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            VStack(spacing: AppTheme.Spacing.m) {
                infoRow(label: "Post", value: slot.postName)
                infoRow(label: "Session", value: slot.sessionName)

                HStack {
                    Text("Coverage")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                    Spacer()

                    Text("\(slot.filled)/\(slot.capacity)")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(slot.isFilled ? AppTheme.StatusColors.accepted : AppTheme.StatusColors.warning)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Volunteers Card

    private var volunteersCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("Assigned Volunteers")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

                Spacer()

                Text("\(slot.assignments.count)")
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(AppTheme.themeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.themeColor.opacity(0.1))
                    .clipShape(Capsule())
            }

            if slot.assignments.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: AppTheme.Spacing.s) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 28))
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        Text("No volunteers assigned")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                    Spacer()
                }
                .padding(.vertical, AppTheme.Spacing.l)
            } else {
                VStack(spacing: AppTheme.Spacing.s) {
                    ForEach(slot.assignments) { assignment in
                        AssignmentRow(assignment: assignment, colorScheme: colorScheme)
                    }
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Add Volunteer Button

    private var addVolunteerButton: some View {
        Button {
            showVolunteerPicker = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Assign Volunteer")
            }
            .font(AppTheme.Typography.headline)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.ButtonHeight.medium)
            .foregroundStyle(.white)
            .background(AppTheme.themeColor)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            Spacer()

            Text(value)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Assignment Row

struct AssignmentRow: View {
    let assignment: CoverageAssignment
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Avatar
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Text(initials)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(statusColor)
            }

            // Name and check-in status
            VStack(alignment: .leading, spacing: 2) {
                Text("\(assignment.volunteer.firstName) \(assignment.volunteer.lastName)")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundStyle(.primary)

                if let checkIn = assignment.checkIn {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text("Checked in \(checkIn.checkInTime, style: .time)")
                    }
                    .font(AppTheme.Typography.captionSmall)
                    .foregroundStyle(AppTheme.StatusColors.accepted)
                }
            }

            Spacer()

            // Status indicator
            if assignment.checkIn != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.StatusColors.accepted)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
        }
        .padding(AppTheme.Spacing.s)
        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
    }

    private var initials: String {
        let first = assignment.volunteer.firstName.prefix(1)
        let last = assignment.volunteer.lastName.prefix(1)
        return String(first + last).uppercased()
    }

    private var statusColor: Color {
        assignment.checkIn != nil ? AppTheme.StatusColors.accepted : AppTheme.themeColor
    }
}
