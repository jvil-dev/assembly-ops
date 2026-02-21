//
//  MyAttendantMeetingsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/20/26.
//

// MARK: - My Attendant Meetings View
//
// Read-only view for attendant volunteers to see their assigned meetings.
// Shows meeting date, session, notes, and attendee count.
//

import SwiftUI

struct MyAttendantMeetingsView: View {
    @StateObject private var viewModel = AttendantVolunteerViewModel()
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                if viewModel.isLoading && viewModel.myMeetings.isEmpty {
                    LoadingView(message: "attendant.meetings.myTitle".localized)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                } else if viewModel.myMeetings.isEmpty {
                    emptyState
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                } else {
                    ForEach(Array(viewModel.myMeetings.enumerated()), id: \.element.id) { index, meeting in
                        meetingCard(meeting)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.05)
                    }
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("attendant.meetings.myTitle".localized)
        .refreshable {
            if let eventId = appState.currentVolunteer?.eventId {
                await viewModel.loadMyMeetings(eventId: eventId)
            }
        }
        .task {
            if let eventId = appState.currentVolunteer?.eventId {
                await viewModel.loadMyMeetings(eventId: eventId)
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
        .alert("common.error".localized, isPresented: .constant(viewModel.error != nil)) {
            Button("common.ok".localized) { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    // MARK: - Meeting Card

    private func meetingCard(_ meeting: AttendantMeetingItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Session & date header
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(AppTheme.themeColor)
                Text(meeting.sessionName)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
            }

            // Meeting date
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                Text(meeting.meetingDate, style: .date)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            // Created by
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                Text(meeting.createdByName)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            // Notes
            if let notes = meeting.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack(spacing: 6) {
                        Image(systemName: "note.text")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.themeColor)
                        Text("attendant.meetings.notes".localized.uppercased())
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                    Text(notes)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(.primary)
                }
                .padding(.top, AppTheme.Spacing.xs)
            } else {
                Text("attendant.meetings.noNotes".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    .italic()
            }

            // Attendee count
            HStack(spacing: 6) {
                Image(systemName: "person.3")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.themeColor)
                Text("\(meeting.attendees.count) \("attendant.meetings.attendees".localized)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
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
            Text("attendant.meetings.noMeetings".localized)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxl)
    }
}

#Preview {
    NavigationStack {
        MyAttendantMeetingsView()
            .environmentObject(AppState.shared)
    }
}
