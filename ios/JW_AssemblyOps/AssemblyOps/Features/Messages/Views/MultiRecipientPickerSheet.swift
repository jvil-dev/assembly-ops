//
//  MultiRecipientPickerSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

// MARK: - Multi-Recipient Picker Sheet
//
// Checkbox-style multi-select volunteer picker for sending to multiple recipients.
//
// Features:
//   - Search volunteers by name
//   - Select all / deselect all
//   - Checkbox rows with selection count badge
//   - Confirm button with count
//
// Used by: MessageComposeView (overseer multi-send)

import SwiftUI

struct MultiRecipientPickerSheet: View {
    @Binding var selectedIds: Set<String>

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = VolunteersViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared

    @State private var searchText = ""
    @State private var hasAppeared = false

    private var accentColor: Color {
        if let deptType = sessionState.selectedDepartment?.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    var filteredVolunteers: [VolunteerListItem] {
        if searchText.isEmpty {
            return viewModel.volunteers
        }
        return viewModel.volunteers.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "messages.compose.loadingVolunteers".localized)
                } else if filteredVolunteers.isEmpty {
                    emptyState
                } else {
                    volunteerList
                }
            }
            .themedBackground(scheme: colorScheme)
            .searchable(text: $searchText, prompt: "messages.compose.searchVolunteers".localized)
            .navigationTitle("messages.compose.selectRecipients".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("general.cancel".localized) {
                        HapticManager.shared.lightTap()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        HapticManager.shared.lightTap()
                        dismiss()
                    } label: {
                        if selectedIds.isEmpty {
                            Text("general.done".localized)
                        } else {
                            Text("\("general.done".localized) (\(selectedIds.count))")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
        .task {
            if let deptId = sessionState.selectedDepartment?.id ?? sessionState.claimedDepartment?.id {
                viewModel.departmentId = deptId
                await viewModel.loadVolunteers()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Spacer()

            Image(systemName: "person.3")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Text("messages.compose.noVolunteers".localized)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text(searchText.isEmpty
                ? "messages.compose.noVolunteers.subtitle".localized
                : "messages.compose.noVolunteersSearch".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppTheme.Spacing.screenEdge)
        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
    }

    // MARK: - Volunteer List

    private var volunteerList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.s) {
                // Select All / Deselect All
                selectAllRow
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                ForEach(Array(filteredVolunteers.enumerated()), id: \.element.id) { index, volunteer in
                    Button {
                        HapticManager.shared.lightTap()
                        toggleSelection(volunteer.id)
                    } label: {
                        MultiRecipientRow(
                            volunteer: volunteer,
                            isSelected: selectedIds.contains(volunteer.id),
                            colorScheme: colorScheme,
                            accentColor: accentColor
                        )
                    }
                    .buttonStyle(.plain)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index + 1) * 0.02)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.s)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }

    // MARK: - Select All Row

    private var selectAllRow: some View {
        Button {
            HapticManager.shared.lightTap()
            if selectedIds.count == viewModel.volunteers.count {
                selectedIds.removeAll()
            } else {
                selectedIds = Set(viewModel.volunteers.map(\.id))
            }
        } label: {
            HStack(spacing: AppTheme.Spacing.m) {
                Image(systemName: selectedIds.count == viewModel.volunteers.count ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundStyle(accentColor)

                Text(selectedIds.count == viewModel.volunteers.count
                    ? "messages.compose.deselectAll".localized
                    : "messages.compose.selectAll".localized)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)

                Spacer()

                if !selectedIds.isEmpty {
                    Text("\(selectedIds.count)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(accentColor)
                        .clipShape(Capsule())
                }
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }

    private func toggleSelection(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }
}

// MARK: - Multi-Recipient Row

private struct MultiRecipientRow: View {
    let volunteer: VolunteerListItem
    let isSelected: Bool
    let colorScheme: ColorScheme
    var accentColor: Color = AppTheme.themeColor

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Checkbox
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .font(.system(size: 22))
                .foregroundStyle(isSelected ? accentColor : AppTheme.textTertiary(for: colorScheme))

            // Avatar
            ZStack {
                Circle()
                    .fill(isSelected ? accentColor.opacity(0.15) : AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .frame(width: 40, height: 40)

                Text(volunteer.initials)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? accentColor : AppTheme.textSecondary(for: colorScheme))
            }

            // Info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(volunteer.fullName)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.primary)

                Text(volunteer.congregation)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            Spacer()
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .strokeBorder(isSelected ? accentColor.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    MultiRecipientPickerSheet(selectedIds: .constant(Set<String>()))
}
