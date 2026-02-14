//
//  RecipientPickerSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/8/26.
//

// MARK: - Recipient Picker Sheet
//
// Modal for selecting a volunteer as a message recipient.
// Follows VolunteerPickerSheet pattern but simplified - just select and dismiss.
//
// Parameters:
//   - selectedVolunteerId: Binding to store selected volunteer ID
//   - selectedVolunteerName: Binding to store selected volunteer name
//
// Features:
//   - Warm gradient background matching app design system
//   - Floating volunteer cards with avatar
//   - Search volunteers by name
//   - Entrance animations
//   - Immediate dismiss on selection (no confirmation step)
//

import SwiftUI

struct RecipientPickerSheet: View {
    @Binding var selectedVolunteerId: String?
    @Binding var selectedVolunteerName: String?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = VolunteersViewModel()
    @ObservedObject private var sessionState = OverseerSessionState.shared

    @State private var searchText = ""
    @State private var hasAppeared = false

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
            ZStack {
                // Warm background
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()

                Group {
                    if viewModel.isLoading {
                        LoadingView(message: "Loading volunteers...")
                    } else if filteredVolunteers.isEmpty {
                        emptyState
                    } else {
                        volunteerList
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search volunteers...")
            .navigationTitle("Select Volunteer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.shared.lightTap()
                        dismiss()
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
            // Load volunteers for current department
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

            Text("No Volunteers")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text(searchText.isEmpty
                ? "Add volunteers to your department first"
                : "No volunteers match your search")
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
            LazyVStack(spacing: AppTheme.Spacing.m) {
                ForEach(Array(filteredVolunteers.enumerated()), id: \.element.id) { index, volunteer in
                    Button {
                        HapticManager.shared.lightTap()
                        selectedVolunteerId = volunteer.id
                        selectedVolunteerName = volunteer.fullName
                        dismiss()
                    } label: {
                        RecipientPickerRow(
                            volunteer: volunteer,
                            isSelected: selectedVolunteerId == volunteer.id,
                            colorScheme: colorScheme
                        )
                    }
                    .buttonStyle(.plain)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.02)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.s)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }
}

// MARK: - Recipient Picker Row

private struct RecipientPickerRow: View {
    let volunteer: VolunteerListItem
    let isSelected: Bool
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Avatar with initials
            ZStack {
                Circle()
                    .fill(isSelected ? AppTheme.themeColor.opacity(0.15) : AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .frame(width: 44, height: 44)

                Text(volunteer.initials)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? AppTheme.themeColor : AppTheme.textSecondary(for: colorScheme))
            }

            // Volunteer info
            VStack(alignment: .leading, spacing: 4) {
                Text(volunteer.fullName)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)

                Text(volunteer.congregation)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            Spacer()

            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.themeColor)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .strokeBorder(isSelected ? AppTheme.themeColor.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    RecipientPickerSheet(
        selectedVolunteerId: .constant(nil),
        selectedVolunteerName: .constant(nil)
    )
}
