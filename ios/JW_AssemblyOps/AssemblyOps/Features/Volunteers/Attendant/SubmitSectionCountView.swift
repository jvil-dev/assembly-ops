//
//  SubmitSectionCountView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/16/26.
//

// MARK: - Submit Section Count View
//
// Form for submitting attendance count for a post.
// Shows post name (read-only), session picker, count input, notes field, submit button.
//

import SwiftUI

struct SubmitSectionCountView: View {
    let post: AttendantPostItem
    @StateObject private var viewModel = AttendantVolunteerViewModel()
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false
    @State private var count: Int = 0
    @State private var notes = ""
    @State private var didSubmit = false
    @State private var sessions: [SessionAttendanceSummaryItem] = []
    @State private var selectedSessionId: String?

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Post info (read-only)
                VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                    SectionHeaderLabel(icon: "map", title: "attendant.count.post".localized)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.name)
                            .font(AppTheme.Typography.headline)
                        if let location = post.location {
                            Text(location)
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        }
                    }
                    .padding(AppTheme.Spacing.m)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .cornerRadius(AppTheme.CornerRadius.small)
                }
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                // Session picker
                if !sessions.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                        SectionHeaderLabel(icon: "calendar", title: "attendant.count.session".localized)

                        ForEach(sessions) { session in
                            Button {
                                selectedSessionId = session.id
                                HapticManager.shared.lightTap()
                            } label: {
                                HStack {
                                    Text(session.sessionName)
                                        .font(AppTheme.Typography.subheadline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedSessionId == session.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AppTheme.themeColor)
                                    }
                                }
                                .padding(AppTheme.Spacing.m)
                                .background(
                                    selectedSessionId == session.id
                                        ? AppTheme.themeColor.opacity(0.1)
                                        : AppTheme.cardBackgroundSecondary(for: colorScheme)
                                )
                                .cornerRadius(AppTheme.CornerRadius.small)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                }

                // Count input
                VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                    SectionHeaderLabel(icon: "number", title: "attendant.count.count".localized)

                    Picker("", selection: $count) {
                        ForEach(0...500, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .cornerRadius(AppTheme.CornerRadius.small)
                }
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

                // Notes
                VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                    SectionHeaderLabel(icon: "note.text", title: "attendant.meetings.notes".localized)

                    TextField("", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                }
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)

                // Submit button
                Button {
                    Task {
                        guard count > 0,
                              let sessionId = selectedSessionId else { return }
                        let noteText = notes.isEmpty ? nil : notes
                        await viewModel.submitPostCount(
                            postId: post.id,
                            postName: post.name,
                            sessionId: sessionId,
                            count: count,
                            notes: noteText
                        )
                        didSubmit = true
                    }
                } label: {
                    HStack {
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("attendant.count.submit".localized)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.m)
                    .foregroundStyle(.white)
                    .background(count > 0 && selectedSessionId != nil ? AppTheme.themeColor : Color.gray)
                    .cornerRadius(AppTheme.CornerRadius.button)
                }
                .disabled(count == 0 || selectedSessionId == nil || viewModel.isSaving)
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.2)
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("attendant.count.title".localized)
        .alert("attendant.count.success".localized, isPresented: $didSubmit) {
            Button("common.ok".localized) { dismiss() }
        }
        .alert("common.error".localized, isPresented: .constant(viewModel.error != nil)) {
            Button("common.ok".localized) { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
        .task {
            if let eventId = appState.currentVolunteer?.eventId {
                if let summaries = try? await AttendanceService.shared.fetchEventAttendanceSummary(eventId: eventId) {
                    sessions = summaries
                    selectedSessionId = summaries.first?.id
                }
            }
        }
    }

}
