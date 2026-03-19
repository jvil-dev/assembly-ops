//
//  EditMeetingSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/17/26.
//

// MARK: - Edit Meeting Sheet
//
// Modal form for editing an existing attendant meeting.
// Fields: session (read-only), meeting date/time, notes, multi-select attendee picker.
//

import SwiftUI

struct EditMeetingSheet: View {
    let meeting: AttendantMeetingItem

    @StateObject private var viewModel = AttendantMeetingViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared
    @StateObject private var volunteersVM = VolunteersViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false
    @State private var showError = false

    // Form state — pre-filled from meeting
    @State private var name: String
    @State private var meetingDate: Date
    @State private var notes: String
    @State private var selectedAttendeeIds: Set<String>
    @State private var attendeeSearchText = ""

    private var accentColor: Color {
        if let deptType = sessionState.selectedDepartment?.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return DepartmentColor.color(for: "ATTENDANT")
    }

    init(meeting: AttendantMeetingItem) {
        self.meeting = meeting
        _name = State(initialValue: meeting.name ?? "")
        _meetingDate = State(initialValue: meeting.meetingDate)
        _notes = State(initialValue: meeting.notes ?? "")
        _selectedAttendeeIds = State(initialValue: Set(meeting.attendees.map { $0.volunteerId }))
    }

    var isFormValid: Bool {
        !selectedAttendeeIds.isEmpty
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
                    sessionCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    nameCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    datePickerCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

                    notesCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)

                    attendeePickerCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.2)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("attendant.meetings.editTitle".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { sheetToolbar }
            .alert("attendant.meetings.editTitle".localized, isPresented: $viewModel.didUpdate) {
                Button("common.ok".localized) { dismiss() }
            } message: {
                Text("attendant.meetings.updated".localized)
            }
            .alert("common.error".localized, isPresented: $showError) {
                Button("common.ok".localized) { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .onChange(of: viewModel.error) { _, newValue in showError = newValue != nil }
            .task {
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

    // MARK: - Meeting Name

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            SectionHeaderLabel(icon: "tag", title: "attendant.meetings.name".localized, accentColor: accentColor)

            TextField("", text: $name)
                .padding(AppTheme.Spacing.s)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
    }

    // MARK: - Session (Read-Only)

    private var sessionCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            SectionHeaderLabel(icon: "calendar", title: "attendant.meetings.session".localized, accentColor: accentColor)

            HStack {
                Text(meeting.sessionName)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "lock.fill")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
            .padding(AppTheme.Spacing.m)
            .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
    }

    // MARK: - Date Picker

    private var datePickerCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            SectionHeaderLabel(icon: "clock", title: "attendant.meetings.date".localized, accentColor: accentColor)

            DatePicker("", selection: $meetingDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .labelsHidden()
        }
    }

    // MARK: - Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            SectionHeaderLabel(icon: "note.text", title: "attendant.meetings.notes".localized, accentColor: accentColor)

            TextField("", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }

    // MARK: - Attendee Picker

    private var attendeePickerCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            attendeeHeader
            attendeeContent
        }
    }

    private var attendeeHeader: some View {
        HStack {
            SectionHeaderLabel(icon: "person.3", title: "attendant.meetings.attendees".localized, accentColor: accentColor)
            Spacer()
            if !selectedAttendeeIds.isEmpty {
                Text("\(selectedAttendeeIds.count) \("attendant.meetings.selected".localized)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(accentColor)
            }
        }
    }

    @ViewBuilder
    private var attendeeContent: some View {
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
            attendeeSearchAndList
        }
    }

    private var attendeeSearchAndList: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                TextField("common.search".localized, text: $attendeeSearchText)
            }
            .padding(AppTheme.Spacing.s)
            .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

            // Select all / deselect all
            selectAllButtons

            // Volunteer list
            ForEach(filteredVolunteers) { volunteer in
                volunteerRow(volunteer)
            }
        }
    }

    private var selectAllButtons: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            Button {
                HapticManager.shared.lightTap()
                selectedAttendeeIds = Set(volunteersVM.volunteers.map { $0.id })
            } label: {
                Text("attendant.meetings.selectAll".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(accentColor)
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
    }

    private func volunteerRow(_ volunteer: VolunteerListItem) -> some View {
        let isSelected = selectedAttendeeIds.contains(volunteer.id)
        return Button {
            HapticManager.shared.lightTap()
            if isSelected {
                selectedAttendeeIds.remove(volunteer.id)
            } else {
                selectedAttendeeIds.insert(volunteer.id)
            }
        } label: {
            volunteerRowContent(volunteer, isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }

    private func volunteerRowContent(_ volunteer: VolunteerListItem, isSelected: Bool) -> some View {
        HStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .foregroundStyle(isSelected ? accentColor : AppTheme.textTertiary(for: colorScheme))

            ZStack {
                Circle()
                    .fill(isSelected ? accentColor.opacity(0.15) : AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .frame(width: 32, height: 32)
                Text(volunteer.initials)
                    .font(AppTheme.Typography.caption).fontWeight(.semibold).fontDesign(.rounded)
                    .foregroundStyle(isSelected ? accentColor : AppTheme.textSecondary(for: colorScheme))
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
        .background(isSelected ? accentColor.opacity(0.06) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var sheetToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("common.cancel".localized) { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("common.save".localized) {
                Task {
                    guard let eventId = sessionState.selectedEvent?.id else { return }
                    let nameText = name.isEmpty ? nil : name
                    let dateString = DateUtils.isoFormatter.string(from: meetingDate)
                    let noteText = notes.isEmpty ? nil : notes
                    await viewModel.updateMeeting(
                        id: meeting.id, eventId: eventId,
                        name: nameText, meetingDate: dateString,
                        notes: noteText, attendeeIds: Array(selectedAttendeeIds)
                    )
                }
            }
            .disabled(!isFormValid || viewModel.isSaving)
        }
    }
}

#Preview {
    EditMeetingSheet(meeting: AttendantMeetingItem(
        id: "preview", name: "Parking Lot Briefing", sessionName: "Saturday AM",
        sessionId: "s1", meetingDate: Date(), notes: "Test notes",
        createdByName: "John", attendees: [], createdAt: Date()
    ))
}
