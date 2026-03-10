//
//  SessionSettingsSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/8/26.
//

// MARK: - Session Settings Sheet
//
// Allows a department overseer to configure department-specific session settings:
// start time, end time, and optional notes. These override the session-level times
// for volunteers assigned to the whole session (no specific shift).
//
// Opens from the gear icon on each session card in AssignmentsView.

import SwiftUI

struct SessionSettingsSheet: View {
    let session: EventSessionItem
    let departmentId: String
    let departmentType: String

    @StateObject private var viewModel: SessionSettingsViewModel

    init(session: EventSessionItem, departmentId: String, departmentType: String) {
        self.session = session
        self.departmentId = departmentId
        self.departmentType = departmentType
        _viewModel = StateObject(wrappedValue: SessionSettingsViewModel(sessionName: session.name))
    }
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false

    private var deptColor: Color {
        DepartmentColor.color(for: departmentType)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Loading settings...")
                        .themedBackground(scheme: colorScheme)
                } else {
                    settingsContent
                }
            }
            .navigationTitle(session.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) {
                        Task {
                            await viewModel.save(sessionId: session.id, departmentId: departmentId)
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .alert("common.success".localized, isPresented: $viewModel.didSave) {
                Button("common.ok".localized) { dismiss() }
            } message: {
                Text("Session settings saved.")
            }
            .alert("common.error".localized, isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("common.ok".localized) { viewModel.error = nil }
            } message: {
                if let err = viewModel.error { Text(err) }
            }
            .task {
                await viewModel.load(sessionId: session.id, departmentId: departmentId)
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Content

    private var settingsContent: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                infoCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                timesCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                notesCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
    }

    // MARK: - Info Card

    private var infoCard: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(deptColor)
            Text("Set your department's start and end time for this session. Volunteers with whole-session assignments will see these times.")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Times Card

    private var timesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "clock", title: "DEPARTMENT TIMES")

            VStack(spacing: AppTheme.Spacing.m) {
                timePicker(label: "Start Time", selection: $viewModel.startTime)
                Divider()
                    .background(AppTheme.dividerColor(for: colorScheme))
                timePicker(label: "End Time", selection: $viewModel.endTime)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private func timePicker(label: String, selection: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
            Spacer()
            DatePicker(
                "",
                selection: selection,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .tint(deptColor)
            .environment(\.timeZone, TimeZone(identifier: "UTC")!)
        }
    }

    // MARK: - Notes Card

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "note.text", title: "NOTES")

            TextField("Optional notes for your department", text: $viewModel.notes, axis: .vertical)
                .font(AppTheme.Typography.body)
                .lineLimit(4, reservesSpace: true)
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }
}
