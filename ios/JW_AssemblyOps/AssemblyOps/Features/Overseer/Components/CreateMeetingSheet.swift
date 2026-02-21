//
//  CreateMeetingSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/16/26.
//

// MARK: - Create Meeting Sheet
//
// Modal form for creating a new attendant meeting.
// Fields: session picker, meeting date/time, notes, multi-select attendee picker.
//

import SwiftUI

struct CreateMeetingSheet: View {
    @StateObject private var viewModel = AttendantMeetingViewModel()
    @ObservedObject private var sessionState = OverseerSessionState.shared
    @StateObject private var attendanceVM = AttendanceViewModel()
    @StateObject private var volunteersVM = VolunteersViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false

    // Form state
    @State private var selectedSessionId: String?
    @State private var meetingDate = Date()
    @State private var notes = ""
    @State private var selectedAttendeeIds: Set<String> = []
    @State private var attendeeSearchText = ""

    var isFormValid: Bool {
        selectedSessionId != nil && !selectedAttendeeIds.isEmpty
    }

    private var filteredVolunteers: [VolunteerListItem] {
        if attendeeSearchText.isEmpty { return volunteersVM.volunteers }
        return volunteersVM.volunteers.filter {
            $0.fullName.localizedCaseInsensitiveContains(attendeeSearchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Session picker
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                        SectionHeaderLabel(icon: "calendar", title: "attendant.meetings.session".localized)

                        if attendanceVM.sessionSummaries.isEmpty {
                            HStack {
                                ProgressView()
                                Text("common.loading".localized)
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            }
                        } else {
                            ForEach(attendanceVM.sessionSummaries, id: \.sessionId) { session in
                                Button {
                                    selectedSessionId = session.sessionId
                                    HapticManager.shared.lightTap()
                                } label: {
                                    HStack {
                                        Text(session.sessionName)
                                            .font(AppTheme.Typography.subheadline)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if selectedSessionId == session.sessionId {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(AppTheme.themeColor)
                                        }
                                    }
                                    .padding(AppTheme.Spacing.m)
                                    .background(
                                        selectedSessionId == session.sessionId
                                            ? AppTheme.themeColor.opacity(0.1)
                                            : AppTheme.cardBackgroundSecondary(for: colorScheme)
                                    )
                                    .cornerRadius(AppTheme.CornerRadius.small)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Meeting date/time
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                        SectionHeaderLabel(icon: "clock", title: "attendant.meetings.date".localized)

                        DatePicker("", selection: $meetingDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // Notes
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                        SectionHeaderLabel(icon: "note.text", title: "attendant.meetings.notes".localized)

                        TextField("", text: $notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

                    // Attendee multi-select
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                        HStack {
                            SectionHeaderLabel(icon: "person.3", title: "attendant.meetings.attendees".localized)
                            Spacer()
                            if !selectedAttendeeIds.isEmpty {
                                Text("\(selectedAttendeeIds.count) \("attendant.meetings.selected".localized)")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.themeColor)
                            }
                        }

                        if volunteersVM.isLoading {
                            HStack {
                                ProgressView()
                                Text("common.loading".localized)
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            }
                            .padding(AppTheme.Spacing.m)
                        } else if volunteersVM.volunteers.isEmpty {
                            Text("attendant.assign.noVolunteers".localized)
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                                .padding(AppTheme.Spacing.m)
                        } else {
                            // Search
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                                TextField("common.search".localized, text: $attendeeSearchText)
                            }
                            .padding(AppTheme.Spacing.s)
                            .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                            .cornerRadius(AppTheme.CornerRadius.small)

                            // Select all / deselect all
                            HStack(spacing: AppTheme.Spacing.m) {
                                Button {
                                    HapticManager.shared.lightTap()
                                    selectedAttendeeIds = Set(volunteersVM.volunteers.map { $0.id })
                                } label: {
                                    Text("attendant.meetings.selectAll".localized)
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(AppTheme.themeColor)
                                }
                                Button {
                                    HapticManager.shared.lightTap()
                                    selectedAttendeeIds.removeAll()
                                } label: {
                                    Text("attendant.meetings.deselectAll".localized)
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                                }
                                Spacer()
                            }

                            // Volunteer list
                            ForEach(filteredVolunteers) { volunteer in
                                Button {
                                    HapticManager.shared.lightTap()
                                    if selectedAttendeeIds.contains(volunteer.id) {
                                        selectedAttendeeIds.remove(volunteer.id)
                                    } else {
                                        selectedAttendeeIds.insert(volunteer.id)
                                    }
                                } label: {
                                    HStack(spacing: AppTheme.Spacing.m) {
                                        // Checkbox
                                        Image(systemName: selectedAttendeeIds.contains(volunteer.id)
                                              ? "checkmark.square.fill"
                                              : "square")
                                            .foregroundStyle(selectedAttendeeIds.contains(volunteer.id)
                                                             ? AppTheme.themeColor
                                                             : AppTheme.textTertiary(for: colorScheme))

                                        // Avatar
                                        ZStack {
                                            Circle()
                                                .fill(selectedAttendeeIds.contains(volunteer.id)
                                                      ? AppTheme.themeColor.opacity(0.15)
                                                      : AppTheme.cardBackgroundSecondary(for: colorScheme))
                                                .frame(width: 32, height: 32)
                                            Text(volunteer.initials)
                                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                .foregroundStyle(selectedAttendeeIds.contains(volunteer.id)
                                                                 ? AppTheme.themeColor
                                                                 : AppTheme.textSecondary(for: colorScheme))
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(volunteer.fullName)
                                                .font(AppTheme.Typography.subheadline)
                                                .foregroundStyle(.primary)
                                            Text(volunteer.congregation)
                                                .font(AppTheme.Typography.caption)
                                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                                        }

                                        Spacer()
                                    }
                                    .padding(AppTheme.Spacing.s)
                                    .background(
                                        selectedAttendeeIds.contains(volunteer.id)
                                            ? AppTheme.themeColor.opacity(0.06)
                                            : Color.clear
                                    )
                                    .cornerRadius(AppTheme.CornerRadius.small)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("attendant.meetings.create".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) {
                        Task {
                            guard let eventId = sessionState.selectedEvent?.id,
                                  let sessionId = selectedSessionId else { return }
                            let noteText = notes.isEmpty ? nil : notes
                            await viewModel.createMeeting(
                                eventId: eventId, sessionId: sessionId,
                                meetingDate: meetingDate, notes: noteText,
                                attendeeIds: Array(selectedAttendeeIds)
                            )
                        }
                    }
                    .disabled(!isFormValid || viewModel.isSaving)
                }
            }
            .alert("attendant.meetings.create".localized, isPresented: $viewModel.didCreate) {
                Button("common.ok".localized) { dismiss() }
            } message: {
                Text("common.success".localized)
            }
            .alert("common.error".localized, isPresented: .constant(viewModel.error != nil)) {
                Button("common.ok".localized) { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .task {
                if let eventId = sessionState.selectedEvent?.id {
                    await attendanceVM.loadEventSummary(eventId: eventId)
                }
                // Load attendant department volunteers for multi-select
                if let deptId = sessionState.selectedDepartment?.id ?? sessionState.claimedDepartment?.id {
                    volunteersVM.departmentId = deptId
                    await volunteersVM.loadVolunteers()
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

}

#Preview {
    CreateMeetingSheet()
}
