//
//  CreateAreaSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

// MARK: - Create Area Sheet
//
// Modal form for overseers to create a new area within the Attendant department.
// Areas group posts together and can have a captain assigned per session.
// Each area belongs to an I/E/S category (Interior, Exterior, or Seating).
//
// Fields:
//   - Required: Name, Category (I/E/S)
//   - Optional: Description, sort order
//

import SwiftUI

struct CreateAreaSheet: View {
    let departmentId: String
    @ObservedObject var viewModel: AreaManagementViewModel

    /// Pre-select an I/E/S category when creating from a specific category section
    var preselectedCategory: AttendantMainCategory? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var name = ""
    @State private var description = ""
    @State private var selectedCategory: AttendantMainCategory?
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var useCustomTime = false
    @State private var startTime: Date = utcDate(hour: 11, minute: 45)
    @State private var endTime: Date = utcDate(hour: 12, minute: 30)

    private static let utcTimeZone = TimeZone(identifier: "UTC")!

    private static func utcDate(hour: Int, minute: Int = 0) -> Date {
        var comps = DateComponents()
        comps.timeZone = TimeZone(identifier: "UTC")
        comps.year = 1970; comps.month = 1; comps.day = 1
        comps.hour = hour; comps.minute = minute; comps.second = 0
        return Calendar(identifier: .gregorian).date(from: comps) ?? Date()
    }

    private var departmentColor: Color {
        DepartmentColor.color(for: "ATTENDANT")
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        selectedCategory != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    categoryCard
                    areaFieldsCard
                    timeRangeCard
                    submitButton
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("area.create".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
            }
            .tint(departmentColor)
            .alert("common.error".localized, isPresented: $showError) {
                Button("common.ok".localized) { viewModel.error = nil }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
            .onChange(of: viewModel.error) { _, error in
                if error != nil { showError = true }
            }
            .onAppear {
                if let preselected = preselectedCategory {
                    selectedCategory = preselected
                }
            }
        }
    }

    // MARK: - Category Card

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "tag", title: "area.category".localized, accentColor: departmentColor)

            HStack(spacing: AppTheme.Spacing.s) {
                ForEach(AttendantMainCategory.allCases) { main in
                    Button {
                        withAnimation(AppTheme.quickAnimation) {
                            selectedCategory = main
                        }
                        HapticManager.shared.lightTap()
                    } label: {
                        HStack(spacing: 4) {
                            Text(main.code)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                            Text(main.rawValue)
                                .font(AppTheme.Typography.caption)
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)
                        .padding(.vertical, AppTheme.Spacing.s)
                        .background(selectedCategory == main
                            ? departmentColor
                            : AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .foregroundStyle(selectedCategory == main ? .white : AppTheme.textSecondary(for: colorScheme))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Fields Card

    private var areaFieldsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "rectangle.3.group", title: "area.details".localized, accentColor: departmentColor)

            VStack(spacing: AppTheme.Spacing.m) {
                themedTextField("area.name".localized, text: $name, placeholder: "area.namePlaceholder".localized)

                themedTextField("area.description".localized, text: $description, placeholder: "area.descriptionPlaceholder".localized)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Time Range Card

    private var timeRangeCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "clock", title: "Area Time Range".localized, accentColor: departmentColor)

            Picker("", selection: $useCustomTime) {
                Text("Whole Session").tag(false)
                Text("Custom").tag(true)
            }
            .pickerStyle(.segmented)
            .tint(departmentColor)

            if useCustomTime {
                VStack(spacing: AppTheme.Spacing.m) {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                        .environment(\.timeZone, Self.utcTimeZone)
                        .tint(departmentColor)

                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                        .environment(\.timeZone, Self.utcTimeZone)
                        .tint(departmentColor)
                }
                .padding(.top, AppTheme.Spacing.xs)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            Task { await createArea() }
        } label: {
            Group {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("area.create".localized)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.ButtonHeight.large)
            .font(AppTheme.Typography.bodyMedium)
            .foregroundStyle(.white)
            .background(isFormValid ? departmentColor : departmentColor.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
        }
        .disabled(!isFormValid || isSubmitting)
    }

    // MARK: - Themed Text Field

    private func themedTextField(_ label: String, text: Binding<String>, placeholder: String = "") -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            TextField(placeholder, text: text)
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
    }

    // MARK: - Actions

    private func createArea() async {
        isSubmitting = true
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedDesc = description.trimmingCharacters(in: .whitespaces)

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = Self.utcTimeZone

        await viewModel.createArea(
            departmentId: departmentId,
            name: trimmedName,
            description: trimmedDesc.isEmpty ? nil : trimmedDesc,
            category: selectedCategory?.rawValue,
            sortOrder: nil,
            startTime: useCustomTime ? formatter.string(from: startTime) : nil,
            endTime: useCustomTime ? formatter.string(from: endTime) : nil
        )

        isSubmitting = false

        if viewModel.error == nil {
            HapticManager.shared.success()
            dismiss()
        } else {
            HapticManager.shared.error()
        }
    }
}

#Preview {
    CreateAreaSheet(
        departmentId: "dept-1",
        viewModel: AreaManagementViewModel()
    )
}
