//
//  AttendanceInputView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/8/26.
//

// MARK: - Attendance Input View
//
// Screen for submitting and managing attendance counts for event sessions.
// Allows department overseers to enter attendance counts with optional section details.
//
// Features:
//   - Session picker to select which session to count
//   - Attendance count input with numeric pad
//   - Optional section identifier (e.g., "Main Auditorium", "Overflow 1")
//   - Optional notes field for additional context
//   - View existing counts for selected session
//   - Edit and delete existing counts
//   - Form validation and error handling
//
// Navigation:
//   - Accessed from OverseerDashboardView via "Log Attendance" button
//   - Dismissed after successful submission

import SwiftUI

struct AttendanceInputView: View {
    @StateObject private var viewModel = AttendanceViewModel()
    @ObservedObject private var sessionState: OverseerSessionState = .shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false

    // No sessions parameter needed — loaded via viewModel.sessionSummaries
    // EventAttendanceSummary query returns ALL sessions (even those with 0 counts)

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                sessionPickerCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                countInputCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                if !viewModel.currentSessionCounts.isEmpty {
                    existingCountsCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("Submit Attendance")
        .task {
            // Load event summary to populate session picker
            if let eventId = sessionState.selectedEvent?.id {
                await viewModel.loadEventSummary(eventId: eventId)
            }
        }
        .onChange(of: viewModel.selectedSessionId) { _, sessionId in
            // When session selection changes, load counts for that session
            if let sessionId {
                Task { await viewModel.loadSessionCounts(sessionId: sessionId) }
            }
        }
        .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("OK") {
                HapticManager.shared.lightTap()
                viewModel.successMessage = nil
            }
        } message: {
            if let message = viewModel.successMessage {
                Text(message)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                HapticManager.shared.lightTap()
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Session Picker Card
    private var sessionPickerCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(AppTheme.themeColor)
                Text("SESSION")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Session picker
            if viewModel.sessionSummaries.isEmpty {
                Text("Loading sessions...")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            } else {
                Menu {
                    ForEach(viewModel.sessionSummaries) { summary in
                        Button {
                            HapticManager.shared.lightTap()
                            viewModel.selectedSessionId = summary.sessionId
                        } label: {
                            VStack(alignment: .leading) {
                                Text(summary.sessionName)
                                Text(summary.sessionDate, style: .date)
                                    .font(.caption)
                            }
                        }
                    }
                } label: {
                    HStack {
                        if let selectedId = viewModel.selectedSessionId,
                           let selected = viewModel.sessionSummaries.first(where: { $0.sessionId == selectedId }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selected.sessionName)
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(Color.primary)
                                Text(selected.sessionDate, style: .date)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                            }
                        } else {
                            Text("Select Session")
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .cornerRadius(AppTheme.CornerRadius.small)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Count Input Card
    private var countInputCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "number")
                    .foregroundStyle(AppTheme.themeColor)
                Text("COUNT DETAILS")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Section name field (optional)
            VStack(alignment: .leading, spacing: 4) {
                Text("Section (optional)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                TextField("e.g., Main Floor, Balcony", text: $viewModel.sectionName)
                    .textFieldStyle(.plain)
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .cornerRadius(AppTheme.CornerRadius.small)
            }

            // Count input
            VStack(alignment: .leading, spacing: 4) {
                Text("Count *")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                TextField("Enter count", text: $viewModel.countText)
                    .textFieldStyle(.plain)
                    .keyboardType(.numberPad)
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .cornerRadius(AppTheme.CornerRadius.small)
            }

            // Notes field (optional)
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes (optional)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                TextField("Any additional details", text: $viewModel.notes)
                    .textFieldStyle(.plain)
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .cornerRadius(AppTheme.CornerRadius.small)
            }

            // Submit button
            Button {
                HapticManager.shared.lightTap()
                Task {
                    await viewModel.submitCount()
                }
            } label: {
                HStack(spacing: AppTheme.Spacing.s) {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Submit Count")
                    }
                }
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.m)
                .background(viewModel.selectedSessionId != nil && !viewModel.countText.isEmpty
                    ? AppTheme.themeColor
                    : AppTheme.textSecondary(for: colorScheme))
                .cornerRadius(AppTheme.CornerRadius.button)
            }
            .disabled(viewModel.selectedSessionId == nil || viewModel.countText.isEmpty || viewModel.isSaving)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Existing Counts Card
    private var existingCountsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "list.bullet")
                    .foregroundStyle(AppTheme.themeColor)
                Text("EXISTING COUNTS")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Counts list
            ForEach(viewModel.currentSessionCounts) { count in
                AttendanceSectionRow(count: count, colorScheme: colorScheme)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            if let sessionId = viewModel.selectedSessionId {
                                Task {
                                    await viewModel.deleteCount(id: count.id, sessionId: sessionId)
                                }
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }
}

// MARK: - Attendance Section Row
private struct AttendanceSectionRow: View {
    let count: AttendanceCountItem
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            VStack(alignment: .leading, spacing: 4) {
                if let section = count.section {
                    Text(section)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                } else {
                    Text("General Count")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                }

                Text("Submitted by \(count.submittedByName)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                if let notes = count.notes {
                    Text(notes)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
            }

            Spacer()

            Text("\(count.count)")
                .font(AppTheme.Typography.largeTitle)
                .foregroundStyle(AppTheme.themeColor)
        }
        .padding(AppTheme.Spacing.m)
        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
        .cornerRadius(AppTheme.CornerRadius.small)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AttendanceInputView()
    }
}
