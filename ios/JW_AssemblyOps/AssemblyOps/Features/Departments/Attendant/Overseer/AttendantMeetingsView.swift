//
//  AttendantMeetingsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/16/26.
//

// MARK: - Attendant Meetings View
//
// List of pre-event attendant meetings.
// Shows session, date/time, attendee count.
// Add meeting opens CreateMeetingSheet.
//

import SwiftUI

struct AttendantMeetingsView: View {
    @StateObject private var viewModel = AttendantMeetingViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showCreateMeeting = false
    @State private var expandedMeetingId: String?
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                if viewModel.isLoading && viewModel.meetings.isEmpty {
                    LoadingView(message: "attendant.meetings.title".localized)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                } else if viewModel.meetings.isEmpty {
                    emptyState
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                } else {
                    ForEach(Array(viewModel.meetings.enumerated()), id: \.element.id) { index, meeting in
                        meetingRow(meeting)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.05)
                    }
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("attendant.meetings.title".localized)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateMeeting = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateMeeting) {
            CreateMeetingSheet()
        }
        .onChange(of: showCreateMeeting) { _, isShowing in
            if !isShowing, let eventId = sessionState.selectedEvent?.id {
                Task { await viewModel.loadMeetings(eventId: eventId) }
            }
        }
        .refreshable {
            if let eventId = sessionState.selectedEvent?.id {
                await viewModel.loadMeetings(eventId: eventId)
            }
        }
        .task {
            if let eventId = sessionState.selectedEvent?.id {
                await viewModel.loadMeetings(eventId: eventId)
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
        .onChange(of: viewModel.error) { _, newValue in showError = newValue != nil }
        .alert("common.error".localized, isPresented: $showError) {
            Button("common.ok".localized) { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    // MARK: - Meeting Row

    private func meetingRow(_ meeting: AttendantMeetingItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(meeting.sessionName)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)

                    Text(formatDate(meeting.meetingDate))
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                    Text("\(meeting.attendees.count)")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.themeColor)
                    Text("attendant.meetings.attendees".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
            }

            if let notes = meeting.notes, !notes.isEmpty {
                Text(notes)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .lineLimit(expandedMeetingId == meeting.id ? nil : 2)
            }

            // Expandable attendee list
            Button {
                withAnimation(AppTheme.quickAnimation) {
                    expandedMeetingId = expandedMeetingId == meeting.id ? nil : meeting.id
                }
            } label: {
                HStack {
                    Image(systemName: "person.3")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.themeColor)
                    Text(expandedMeetingId == meeting.id ? "attendant.meetings.hideAttendees".localized : "attendant.meetings.showAttendees".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.themeColor)
                    Spacer()
                    Image(systemName: expandedMeetingId == meeting.id ? "chevron.up" : "chevron.down")
                        .font(AppTheme.Typography.captionSmall)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
            }
            .buttonStyle(.plain)

            if expandedMeetingId == meeting.id {
                VStack(spacing: AppTheme.Spacing.s) {
                    ForEach(meeting.attendees) { attendee in
                        HStack(spacing: AppTheme.Spacing.s) {
                            Image(systemName: "person.fill")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.themeColor)
                            Text(attendee.volunteerName)
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(AppTheme.Spacing.s)
                        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    }
                }
            }

            // Created by
            Text(String(format: "attendant.meetings.createdBy".localized, meeting.createdByName))
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Text("attendant.meetings.empty".localized)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            Button {
                showCreateMeeting = true
            } label: {
                Text("attendant.meetings.create".localized)
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.vertical, AppTheme.Spacing.m)
                    .background(AppTheme.themeColor)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxl)
    }

    private static let meetingDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private func formatDate(_ date: Date) -> String {
        Self.meetingDateFormatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        AttendantMeetingsView()
    }
}
