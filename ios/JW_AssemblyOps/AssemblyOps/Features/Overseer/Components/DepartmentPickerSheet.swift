//
//  DepartmentPickerSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Department Picker Sheet
//
// Modal list for Event Overseers to switch between departments.
// Uses the app's design system with warm background and floating cards.
//
// Features:
//   - Warm gradient background
//   - Floating department cards with color indicators
//   - Shows volunteer count per department
//   - Entrance animations
//   - Selection updates OverseerSessionState.selectedDepartment
//

import SwiftUI

struct DepartmentPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var sessionState = OverseerSessionState.shared

    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.m) {
                    // "All Departments" option
                    Button {
                        HapticManager.shared.lightTap()
                        sessionState.selectDepartment(nil)
                        dismiss()
                    } label: {
                        HStack(spacing: AppTheme.Spacing.m) {
                            Circle()
                                .fill(AppTheme.themeColor)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "square.grid.2x2")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(.white)
                                )

                            Text("All Departments")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(.primary)

                            Spacer()

                            if sessionState.selectedDepartment == nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(AppTheme.themeColor)
                            }
                        }
                        .cardPadding()
                        .themedCard(scheme: colorScheme)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .strokeBorder(sessionState.selectedDepartment == nil ? AppTheme.themeColor.opacity(0.3) : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    if sessionState.isLoadingDepartments {
                        ProgressView("Loading departments...")
                            .padding(.vertical, AppTheme.Spacing.xl)
                    } else {
                        ForEach(Array(sessionState.departments.enumerated()), id: \.element.id) { index, department in
                            Button {
                                HapticManager.shared.lightTap()
                                sessionState.selectDepartment(department)
                                dismiss()
                            } label: {
                                DepartmentRow(
                                    department: department,
                                    isSelected: department.id == sessionState.selectedDepartment?.id,
                                    colorScheme: colorScheme
                                )
                            }
                            .buttonStyle(.plain)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index + 1) * 0.02)
                        }
                    }
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("Select Department")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }
}

// MARK: - Department Row

private struct DepartmentRow: View {
    let department: DepartmentSummary
    let isSelected: Bool
    let colorScheme: ColorScheme

    private var departmentColor: Color {
        DepartmentColor.color(for: department.departmentType)
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Department color circle
            Circle()
                .fill(departmentColor)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: departmentIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                )

            // Department info
            VStack(alignment: .leading, spacing: 4) {
                Text(department.name)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                    Text("\(department.volunteerCount) volunteers")
                }
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

    private var departmentIcon: String {
        switch department.departmentType.uppercased() {
        case "PARKING": return "car"
        case "ATTENDANT": return "person.badge.shield.checkmark"
        case "AUDIO_VIDEO", "AV": return "video"
        case "CLEANING": return "sparkles"
        case "COMMITTEE": return "person.3"
        case "FIRST_AID", "FIRSTAID": return "cross"
        case "BAPTISM": return "drop"
        case "INFORMATION", "INFORMATION_VOLUNTEER_SERVICE": return "info.circle"
        case "ACCOUNTS": return "dollarsign.circle"
        case "INSTALLATION": return "hammer"
        case "LOST_FOUND", "LOST_AND_FOUND", "LOST_FOUND_CHECKROOM": return "tray"
        case "ROOMING": return "bed.double"
        case "TRUCKING", "TRUCKING_EQUIPMENT": return "truck.box"
        default: return "person"
        }
    }
}

#Preview {
    DepartmentPickerSheet()
}
