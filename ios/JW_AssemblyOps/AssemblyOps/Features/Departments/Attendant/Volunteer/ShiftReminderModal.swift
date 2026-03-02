//
//  ShiftReminderModal.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/1/26.
//

// MARK: - Shift Reminder Modal
//
// Full-screen blocking modal that requires attendant volunteers to read
// and confirm CO-23 reminders before each shift. Cannot be dismissed
// without confirming.
//
// Features:
//   - Numbered CO-23 reminder items
//   - "I've read and understood" button (enabled after scrolling to bottom)
//   - Calls confirmShiftReminder on confirmation
//   - .interactiveDismissDisabled(true) prevents swipe dismiss
//

import SwiftUI

struct ShiftReminderModal: View {
    let shiftId: String
    let shiftName: String
    @ObservedObject var viewModel: ShiftReminderViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var hasScrolledToBottom = false
    @State private var isConfirming = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    ScrollViewReader { proxy in
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                            headerSection

                            remindersList

                            // Bottom marker for scroll detection
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                                .onAppear {
                                    hasScrolledToBottom = true
                                }
                        }
                        .screenPadding()
                        .padding(.top, AppTheme.Spacing.l)
                        .padding(.bottom, AppTheme.Spacing.xl)
                    }
                }

                confirmButton
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("reminder.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(true)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.title2)
                    .foregroundStyle(DepartmentColor.color(for: "ATTENDANT"))
                Text("reminder.header".localized)
                    .font(AppTheme.Typography.headline)
                    .fontWeight(.semibold)
            }

            Text(String(format: "reminder.subtitle".localized, shiftName))
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(AppTheme.StatusColors.info)
                Text("reminder.scrollHint".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Reminders List

    private var remindersList: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "list.clipboard", title: "reminder.listTitle".localized)

            ForEach(Array(ShiftReminderContent.reminders.enumerated()), id: \.offset) { index, reminder in
                reminderRow(number: index + 1, reminder: reminder)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private func reminderRow(number: Int, reminder: ShiftReminderContent.ReminderItem) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.m) {
            Text("\(number)")
                .font(AppTheme.Typography.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(DepartmentColor.color(for: "ATTENDANT"))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(reminder.title.localized)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundStyle(.primary)
                Text(reminder.detail.localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        VStack(spacing: AppTheme.Spacing.s) {
            Divider()

            Button {
                Task { await confirmReminder() }
            } label: {
                Group {
                    if isConfirming {
                        ProgressView().tint(.white)
                    } else {
                        HStack(spacing: AppTheme.Spacing.s) {
                            Image(systemName: "checkmark.shield.fill")
                            Text("reminder.confirm".localized)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.ButtonHeight.large)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundStyle(.white)
                .background(hasScrolledToBottom ? DepartmentColor.color(for: "ATTENDANT") : DepartmentColor.color(for: "ATTENDANT").opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
            }
            .disabled(!hasScrolledToBottom || isConfirming)
            .screenPadding()
            .padding(.bottom, AppTheme.Spacing.m)
        }
        .background(AppTheme.cardBackground(for: colorScheme))
    }

    // MARK: - Confirm

    private func confirmReminder() async {
        isConfirming = true
        await viewModel.confirmShiftReminder(shiftId: shiftId)
        isConfirming = false

        if viewModel.error == nil {
            HapticManager.shared.success()
            dismiss()
        }
    }
}

// MARK: - CO-23 Reminder Content

/// Static CO-23 reminder content for attendant volunteers.
/// Stored locally — not fetched from backend.
struct ShiftReminderContent {
    struct ReminderItem {
        let title: String
        let detail: String
    }

    static let reminders: [ReminderItem] = [
        ReminderItem(
            title: "reminder.item1.title",
            detail: "reminder.item1.detail"
        ),
        ReminderItem(
            title: "reminder.item2.title",
            detail: "reminder.item2.detail"
        ),
        ReminderItem(
            title: "reminder.item3.title",
            detail: "reminder.item3.detail"
        ),
        ReminderItem(
            title: "reminder.item4.title",
            detail: "reminder.item4.detail"
        ),
        ReminderItem(
            title: "reminder.item5.title",
            detail: "reminder.item5.detail"
        ),
        ReminderItem(
            title: "reminder.item6.title",
            detail: "reminder.item6.detail"
        ),
        ReminderItem(
            title: "reminder.item7.title",
            detail: "reminder.item7.detail"
        ),
        ReminderItem(
            title: "reminder.item8.title",
            detail: "reminder.item8.detail"
        ),
        ReminderItem(
            title: "reminder.item9.title",
            detail: "reminder.item9.detail"
        ),
        ReminderItem(
            title: "reminder.item10.title",
            detail: "reminder.item10.detail"
        ),
    ]
}

#Preview {
    ShiftReminderModal(
        shiftId: "1",
        shiftName: "Morning Exterior",
        viewModel: ShiftReminderViewModel()
    )
}
