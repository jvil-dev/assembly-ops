//
//  ReminderComplianceView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/1/26.
//

// MARK: - Reminder Compliance View
//
// Overseer view showing per-shift reminder confirmation compliance.
// Displays which volunteers have confirmed their pre-shift reminders
// and which are still pending.
//
// Features:
//   - Session picker → shift picker
//   - Per-shift compliance grid: green checkmark = confirmed, gray = pending
//   - Summary counts (confirmed / total)
//

import SwiftUI

struct ReminderComplianceView: View {
    @StateObject private var shiftVM = ShiftManagementViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var selectedShiftId: String?
    @State private var complianceData: ComplianceData?
    @State private var isLoadingCompliance = false

    private var accentColor: Color {
        if let deptType = sessionState.selectedDepartment?.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    private var eventId: String? {
        sessionState.selectedEvent?.id
    }

    var body: some View {
        Group {
            if shiftVM.isLoading && shiftVM.sessions.isEmpty {
                LoadingView(message: "reminder.compliance.title".localized)
                    .themedBackground(scheme: colorScheme)
            } else {
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        sessionPicker
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                        if !shiftVM.shifts.isEmpty {
                            shiftPicker
                                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                        }

                        if let data = complianceData {
                            complianceSection(data)
                                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                        } else if isLoadingCompliance {
                            ProgressView()
                                .padding(.top, AppTheme.Spacing.xl)
                        }
                    }
                    .screenPadding()
                    .padding(.top, AppTheme.Spacing.l)
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }
                .themedBackground(scheme: colorScheme)
                .refreshable {
                    if let shiftId = selectedShiftId {
                        await loadCompliance(shiftId: shiftId)
                    }
                }
            }
        }
        .navigationTitle("reminder.compliance.title".localized)
        .task {
            guard let eventId = eventId else { return }
            await shiftVM.loadSessions(eventId: eventId)
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Session Picker

    private var sessionPicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "calendar", title: "shift.session".localized)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.s) {
                    ForEach(shiftVM.sessions) { session in
                        Button {
                            withAnimation(AppTheme.quickAnimation) {
                                shiftVM.selectedSession = session
                                selectedShiftId = nil
                                complianceData = nil
                            }
                            Task {
                                await shiftVM.loadShifts(sessionId: session.id)
                            }
                            HapticManager.shared.lightTap()
                        } label: {
                            Text(session.name)
                                .font(AppTheme.Typography.subheadline)
                                .fontWeight(shiftVM.selectedSession?.id == session.id ? .semibold : .regular)
                                .padding(.horizontal, AppTheme.Spacing.m)
                                .padding(.vertical, AppTheme.Spacing.s)
                                .background(
                                    shiftVM.selectedSession?.id == session.id
                                        ? accentColor
                                        : AppTheme.cardBackgroundSecondary(for: colorScheme)
                                )
                                .foregroundStyle(
                                    shiftVM.selectedSession?.id == session.id
                                        ? .white
                                        : AppTheme.textSecondary(for: colorScheme)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Shift Picker

    private var shiftPicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "clock", title: "reminder.compliance.selectShift".localized)

            ForEach(shiftVM.shifts) { shift in
                Button {
                    withAnimation(AppTheme.quickAnimation) {
                        selectedShiftId = shift.id
                    }
                    Task {
                        await loadCompliance(shiftId: shift.id)
                    }
                    HapticManager.shared.lightTap()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(shift.name)
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundStyle(.primary)
                            Text(shift.timeRangeDisplay)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        }
                        Spacer()
                        if selectedShiftId == shift.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(accentColor)
                        }
                    }
                    .padding(AppTheme.Spacing.m)
                    .background(
                        selectedShiftId == shift.id
                            ? accentColor.opacity(0.08)
                            : AppTheme.cardBackgroundSecondary(for: colorScheme)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                }
                .buttonStyle(.plain)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Compliance Section

    private func complianceSection(_ data: ComplianceData) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack {
                SectionHeaderLabel(icon: "checkmark.shield", title: "reminder.compliance.status".localized)
                Spacer()
                Text("\(data.totalConfirmed)/\(data.totalAssigned)")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundStyle(data.totalConfirmed == data.totalAssigned ? AppTheme.StatusColors.accepted : AppTheme.StatusColors.warning)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(data.totalConfirmed == data.totalAssigned ? AppTheme.StatusColors.accepted : accentColor)
                        .frame(width: data.totalAssigned > 0 ? geo.size.width * CGFloat(data.totalConfirmed) / CGFloat(data.totalAssigned) : 0, height: 8)
                }
            }
            .frame(height: 8)

            ForEach(data.volunteers, id: \.eventVolunteerId) { vol in
                HStack(spacing: AppTheme.Spacing.m) {
                    Image(systemName: vol.confirmed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(vol.confirmed ? AppTheme.StatusColors.accepted : AppTheme.textTertiary(for: colorScheme))

                    Text("\(vol.firstName) \(vol.lastName)")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(.primary)

                    Spacer()

                    if vol.confirmed, let confirmedAt = vol.confirmedAt {
                        Text(confirmedAt)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    } else {
                        Text("reminder.compliance.pending".localized)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.StatusColors.warning)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }

            if data.volunteers.isEmpty {
                Text("reminder.compliance.noAssignments".localized)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.l)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Load Compliance

    private func loadCompliance(shiftId: String) async {
        isLoadingCompliance = true
        do {
            complianceData = try await AttendantService.shared.fetchShiftReminderStatus(shiftId: shiftId)
        } catch {
            print("[ReminderCompliance] Failed to load: \(error)")
        }
        isLoadingCompliance = false
    }
}

// MARK: - Compliance Data Model

struct ComplianceData {
    let shiftId: String
    let shiftName: String
    let totalAssigned: Int
    let totalConfirmed: Int
    let volunteers: [VolunteerComplianceStatus]
}

struct VolunteerComplianceStatus {
    let eventVolunteerId: String
    let firstName: String
    let lastName: String
    let confirmed: Bool
    let confirmedAt: String?
}

#Preview {
    NavigationStack {
        ReminderComplianceView()
    }
}
