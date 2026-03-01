//
//  WalkThroughChecklistView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/22/26.
//

// MARK: - Walk-Through Checklist View
//
// Morning walk-through checklist for Attendant captains.
// Implements CO-1 §7 / CO-23 §3-9 security sweep items.
// Persists completions to backend via AttendantVolunteerViewModel.
//

import SwiftUI

struct WalkThroughChecklistView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var appState: AppState

    @ObservedObject var attendantVM: AttendantVolunteerViewModel
    let sessions: [VolunteerSessionItem]

    @State private var selectedSessionId: String?
    @State private var checkedItems: Set<Int> = []
    @State private var itemNotes: [Int: String] = [:]
    @State private var expandedItem: Int?
    @State private var showCompletion = false
    @State private var showDismissWarning = false
    @State private var completionTime = Date()
    @State private var hasAppeared = false

    private let checklistItems: [String] = [
        "attendant.walkthrough.item.1",
        "attendant.walkthrough.item.2",
        "attendant.walkthrough.item.3",
        "attendant.walkthrough.item.4",
        "attendant.walkthrough.item.5",
        "attendant.walkthrough.item.6",
        "attendant.walkthrough.item.7",
        "attendant.walkthrough.item.8"
    ]

    private var isComplete: Bool { checkedItems.count == checklistItems.count }

    private var isSessionAlreadyCompleted: Bool {
        guard let sid = selectedSessionId else { return false }
        return attendantVM.hasCompletedWalkThrough(for: sid)
    }

    private var sessionName: String {
        sessions.first(where: { $0.id == selectedSessionId })?.name ?? "attendant.walkthrough.session.placeholder".localized
    }

    private var formattedCompletionTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: completionTime)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    sessionPickerCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    progressCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    checklistCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

                    completeButton
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("attendant.walkthrough.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close".localized) {
                        if !checkedItems.isEmpty && !isComplete {
                            showDismissWarning = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .alert("attendant.walkthrough.dismiss.title".localized, isPresented: $showDismissWarning) {
                Button("attendant.walkthrough.dismiss.confirm".localized, role: .destructive) { dismiss() }
                Button("common.cancel".localized, role: .cancel) { }
            } message: {
                Text(String(format: "attendant.walkthrough.dismiss.message".localized, checkedItems.count, checklistItems.count))
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
                if selectedSessionId == nil, let first = sessions.first {
                    selectedSessionId = first.id
                }
            }
            .alert("attendant.walkthrough.complete.title".localized, isPresented: $showCompletion) {
                Button("Done") { dismiss() }
            } message: {
                Text(String(
                    format: "attendant.walkthrough.complete.message".localized,
                    checklistItems.count,
                    sessionName,
                    formattedCompletionTime
                ))
            }
        }
    }

    // MARK: - Session Picker Card

    private var sessionPickerCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "calendar")
                    .foregroundStyle(AppTheme.themeColor)
                Text("attendant.attendance.session".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            if sessions.isEmpty {
                Text("attendant.walkthrough.session.placeholder".localized)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.s) {
                        ForEach(sessions) { session in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedSessionId = session.id
                                }
                                HapticManager.shared.lightTap()
                            } label: {
                                HStack(spacing: AppTheme.Spacing.xs) {
                                    if attendantVM.hasCompletedWalkThrough(for: session.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(AppTheme.Typography.caption)
                                    }
                                    Text(session.name)
                                }
                                .font(AppTheme.Typography.subheadline)
                                .padding(.horizontal, AppTheme.Spacing.m)
                                .padding(.vertical, AppTheme.Spacing.s)
                                .background(
                                    selectedSessionId == session.id
                                        ? AppTheme.themeColor
                                        : AppTheme.cardBackgroundSecondary(for: colorScheme)
                                )
                                .foregroundStyle(selectedSessionId == session.id ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Progress Card

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "checklist")
                    .foregroundStyle(AppTheme.themeColor)
                Text(String(format: "attendant.walkthrough.progress".localized, checkedItems.count, checklistItems.count))
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
                Spacer()
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.StatusColors.accepted)
                }
            }

            ProgressView(value: Double(checkedItems.count), total: Double(checklistItems.count))
                .tint(isComplete ? AppTheme.StatusColors.accepted : AppTheme.themeColor)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Checklist Card

    private var checklistCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "shield.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("attendant.concerns.report".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
            .padding(.bottom, AppTheme.Spacing.m)

            ForEach(Array(checklistItems.enumerated()), id: \.offset) { index, key in
                checklistRow(index: index, text: key.localized)

                if index < checklistItems.count - 1 {
                    Divider()
                        .padding(.vertical, AppTheme.Spacing.s)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    @ViewBuilder
    private func checklistRow(index: Int, text: String) -> some View {
        let isChecked = checkedItems.contains(index)
        let isExpanded = expandedItem == index

        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.m) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isChecked {
                            checkedItems.remove(index)
                        } else {
                            checkedItems.insert(index)
                            if isComplete {
                                HapticManager.shared.success()
                            } else {
                                HapticManager.shared.lightTap()
                            }
                        }
                    }
                } label: {
                    Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isChecked ? AppTheme.StatusColors.accepted : AppTheme.textTertiary(for: colorScheme))
                        .font(.system(size: 22))
                }
                .buttonStyle(.plain)

                Text(text)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(isChecked ? AppTheme.textSecondary(for: colorScheme) : .primary)
                    .strikethrough(isChecked, color: AppTheme.textSecondary(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedItem = isExpanded ? nil : index
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        .font(.caption)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                TextField("Notes (optional)", text: Binding(
                    get: { itemNotes[index] ?? "" },
                    set: { itemNotes[index] = $0 }
                ))
                .font(AppTheme.Typography.caption)
                .padding(AppTheme.Spacing.s)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                .padding(.leading, 38)
            }
        }
    }

    // MARK: - Complete Button

    private var completeButton: some View {
        Button {
            Task {
                guard let eventId = appState.currentEventId,
                      let sessionId = selectedSessionId else { return }
                let notes = itemNotes.values.filter { !$0.isEmpty }.joined(separator: "; ")
                await attendantVM.submitWalkThrough(
                    eventId: eventId,
                    sessionId: sessionId,
                    itemCount: checklistItems.count,
                    notes: notes.isEmpty ? nil : notes
                )
                if attendantVM.error == nil {
                    completionTime = Date()
                    HapticManager.shared.success()
                    showCompletion = true
                }
            }
        } label: {
            HStack(spacing: AppTheme.Spacing.s) {
                if attendantVM.isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("attendant.walkthrough.complete.button".localized)
                }
            }
            .font(AppTheme.Typography.bodyMedium)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.ButtonHeight.medium / 2)
            .background(isComplete && !attendantVM.isSaving && !isSessionAlreadyCompleted ? AppTheme.themeColor : AppTheme.textTertiary(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
        }
        .buttonStyle(.plain)
        .disabled(!isComplete || attendantVM.isSaving || isSessionAlreadyCompleted)
    }
}

#Preview {
    WalkThroughChecklistView(
        attendantVM: AttendantVolunteerViewModel(),
        sessions: [
            VolunteerSessionItem(
                id: "s1", name: "Morning Session",
                date: Date(), startTime: Date(),
                endTime: Date().addingTimeInterval(3600 * 3)
            )
        ]
    )
    .environmentObject(AppState.shared)
}
