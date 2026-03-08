//
//  CaptainAssignmentDetailView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/1/26.
//

// MARK: - Captain Assignment Detail View
//
// Detail view for a captain area assignment.
// Shows area info, session details, and accept/decline controls.
// Mirrors AssignmentDetailView patterns.
//

import SwiftUI

struct CaptainAssignmentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    let assignment: CaptainAssignment
    let onUpdate: () -> Void

    @State private var showDeclineSheet = false
    @State private var declineReason = ""
    @State private var hasAppeared = false
    @State private var isAccepting = false
    @State private var isDeclining = false
    @State private var showError = false
    @State private var errorMessage = ""

    init(assignment: CaptainAssignment, onUpdate: @escaping () -> Void = {}) {
        self.assignment = assignment
        self.onUpdate = onUpdate
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                headerCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                detailsCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                if assignment.canRespond {
                    acceptDeclineCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                }

                if assignment.status == .declined || assignment.status == .autoDeclined {
                    declinedInfoCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("captain.role".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
        .sheet(isPresented: $showDeclineSheet) {
            DeclineReasonSheet(reason: $declineReason) {
                Task {
                    await declineCaptainAssignment()
                }
            }
        }
        .alert("common.error".localized, isPresented: $showError) {
            Button("common.ok".localized, role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("captain.role".localized)
                        .font(AppTheme.Typography.captionBold)
                        .foregroundStyle(AppTheme.StatusColors.warning)

                    Text(assignment.areaName)
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(.primary)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(DepartmentColor.color(for: assignment.departmentType))
                            .frame(width: 10, height: 10)
                        Text(assignment.departmentName)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                }

                Spacer()

                AssignmentStatusBadge(
                    status: assignment.status,
                    isCaptain: true,
                    departmentType: assignment.departmentType
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
                detailRow(icon: "calendar", title: "Date", value: DateUtils.formatSessionDateFull(assignment.date))

                detailRow(icon: "clock", title: "Time", value: assignment.timeRangeFormatted)

                if let description = assignment.areaDescription {
                    detailRow(icon: "mappin", title: "Area", value: description)
                }

                detailRow(icon: "person.2", title: "Session", value: assignment.sessionName)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Accept/Decline Card

    private var acceptDeclineCard: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            if let deadlineText = assignment.deadlineText {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.StatusColors.warning)

                    Text(deadlineText)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.StatusColors.warning)

                    Spacer()
                }
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.vertical, AppTheme.Spacing.s)
                .background(AppTheme.StatusColors.warningBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.badge))
            }

            HStack(spacing: AppTheme.Spacing.m) {
                // Decline button
                Button {
                    isDeclining = true
                    HapticManager.shared.lightTap()
                    showDeclineSheet = true
                } label: {
                    HStack(spacing: AppTheme.Spacing.s) {
                        if isDeclining {
                            ProgressView()
                                .tint(AppTheme.StatusColors.declined)
                        } else {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Text("captain.assignment.decline".localized)
                            .font(AppTheme.Typography.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.ButtonHeight.medium)
                    .foregroundStyle(AppTheme.StatusColors.declined)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                            .fill(AppTheme.StatusColors.declinedBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                            .strokeBorder(AppTheme.StatusColors.declined.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isAccepting || isDeclining)

                // Accept button
                Button {
                    isAccepting = true
                    HapticManager.shared.mediumTap()
                    Task {
                        await acceptCaptainAssignment()
                    }
                } label: {
                    HStack(spacing: AppTheme.Spacing.s) {
                        if isAccepting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Text("captain.assignment.accept".localized)
                            .font(AppTheme.Typography.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.ButtonHeight.medium)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                            .fill(isAccepting ? AppTheme.StatusColors.accepted.opacity(0.5) : AppTheme.StatusColors.accepted)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isAccepting || isDeclining)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Declined Info Card

    private var declinedInfoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(AppTheme.StatusColors.declined)
                Text(assignment.status == .autoDeclined ? "captain.assignment.autoDeclined".localized : "captain.assignment.declined".localized)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.StatusColors.declined)
            }

            if let reason = assignment.declineReason, !reason.isEmpty {
                Text(reason)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Detail Row

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.themeColor)
                .frame(width: 24, height: 24)

            Text(title)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .frame(width: 70, alignment: .leading)

            Text(value)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Actions

    private func acceptCaptainAssignment() async {
        do {
            try await AssignmentsService.shared.acceptAreaCaptain(areaCaptainId: assignment.id)
            HapticManager.shared.success()
            onUpdate()
            dismiss()
        } catch {
            isAccepting = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func declineCaptainAssignment() async {
        do {
            try await AssignmentsService.shared.declineAreaCaptain(
                areaCaptainId: assignment.id,
                reason: declineReason.isEmpty ? nil : declineReason
            )
            HapticManager.shared.success()
            onUpdate()
            dismiss()
        } catch {
            isDeclining = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Previews

#Preview("Pending") {
    NavigationStack {
        CaptainAssignmentDetailView(assignment: .preview)
    }
}

#Preview("Accepted") {
    NavigationStack {
        CaptainAssignmentDetailView(assignment: .previewAccepted)
    }
}
