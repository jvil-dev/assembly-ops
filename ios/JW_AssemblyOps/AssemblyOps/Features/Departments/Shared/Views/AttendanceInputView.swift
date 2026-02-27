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
//   - Accessed from GenericDepartmentView via "Log Attendance" button
//   - Dismissed after successful submission

import SwiftUI

struct AttendanceInputView: View {
    @StateObject private var viewModel = AttendanceViewModel()
    @ObservedObject private var sessionState: EventSessionState = .shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false
    @State private var showError = false
    @State private var showSuccess = false

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
            // Load Attendant department posts for section picker
            await viewModel.loadAttendantPosts(departments: sessionState.departments)
        }
        .onChange(of: viewModel.selectedSessionId) { _, sessionId in
            // When session selection changes, load counts for that session
            if let sessionId {
                Task { await viewModel.loadSessionCounts(sessionId: sessionId) }
            }
        }
        .onChange(of: viewModel.successMessage) { _, newValue in showSuccess = newValue != nil }
        .alert("common.success".localized, isPresented: $showSuccess) {
            Button("common.ok".localized) {
                HapticManager.shared.lightTap()
                viewModel.successMessage = nil
            }
        } message: {
            if let message = viewModel.successMessage {
                Text(message)
            }
        }
        .onChange(of: viewModel.error) { _, newValue in showError = newValue != nil }
        .alert("common.error".localized, isPresented: $showError) {
            Button("common.ok".localized) {
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
            HStack(spacing: AppTheme.Spacing.s) {
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
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
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
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
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
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "number")
                    .foregroundStyle(AppTheme.themeColor)
                Text("COUNT DETAILS")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Section picker (populated from Attendant posts) or free-text fallback
            sectionPickerField

            // Count input
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Count *")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                Picker("", selection: $viewModel.count) {
                    ForEach(0...500, id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
            }

            // Notes field (optional)
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Notes (optional)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                TextField("", text: $viewModel.notes)
                    .textFieldStyle(.plain)
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
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
                .background(viewModel.selectedSessionId != nil && viewModel.count > 0
                    ? AppTheme.themeColor
                    : AppTheme.textSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
            }
            .disabled(viewModel.selectedSessionId == nil || viewModel.count == 0 || viewModel.isSaving)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Section Picker Field
    @ViewBuilder
    private var sectionPickerField: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("attendance.section".localized)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            if !viewModel.attendantPosts.isEmpty && !viewModel.useCustomSection {
                // Post-based picker
                let categories = orderedCategories
                Menu {
                    if categories.count > 1 {
                        // Group by category
                        ForEach(categories, id: \.self) { category in
                            Section(category) {
                                ForEach(viewModel.attendantPosts.filter { ($0.category ?? "attendance.section.other".localized) == category }) { post in
                                    postButton(post)
                                }
                            }
                        }
                    } else {
                        // Flat list
                        ForEach(viewModel.attendantPosts) { post in
                            postButton(post)
                        }
                    }

                    Divider()

                    Button {
                        HapticManager.shared.lightTap()
                        viewModel.useCustomSection = true
                    } label: {
                        Label("attendance.section.other".localized, systemImage: "pencil")
                    }
                } label: {
                    HStack {
                        if let post = viewModel.selectedPost {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(post.name)
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(Color.primary)
                                if let location = post.location {
                                    Text(location)
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                                }
                            }
                        } else {
                            Text("attendance.section.select".localized)
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
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                }
            } else {
                // Fallback: free-text (when no posts exist or "Other" selected)
                HStack {
                    TextField("attendance.section.placeholder".localized, text: $viewModel.sectionName)
                        .textFieldStyle(.plain)
                        .padding(AppTheme.Spacing.m)
                        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

                    if viewModel.useCustomSection {
                        Button {
                            HapticManager.shared.lightTap()
                            viewModel.useCustomSection = false
                            viewModel.sectionName = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }
                    }
                }
            }
        }
    }

    private func postButton(_ post: AttendantPostItem) -> some View {
        Button {
            HapticManager.shared.lightTap()
            viewModel.selectedPost = post
        } label: {
            if let location = post.location {
                Text("\(post.name) (\(location))")
            } else {
                Text(post.name)
            }
        }
    }

    /// Categories in display order, preserving sort order from backend
    private var orderedCategories: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for post in viewModel.attendantPosts {
            let cat = post.category ?? "attendance.section.other".localized
            if seen.insert(cat).inserted {
                result.append(cat)
            }
        }
        return result
    }

    // MARK: - Existing Counts Card
    private var existingCountsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Section header
            HStack(spacing: AppTheme.Spacing.s) {
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
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
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
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AttendanceInputView()
    }
}
