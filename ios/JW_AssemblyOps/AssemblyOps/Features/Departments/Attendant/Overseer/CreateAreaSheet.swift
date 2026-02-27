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
    @State private var sortOrder = ""
    @State private var selectedCategory: AttendantMainCategory?
    @State private var isSubmitting = false

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
            SectionHeaderLabel(icon: "tag", title: "area.category".localized)

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
                            ? DepartmentColor.color(for: "ATTENDANT")
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
            SectionHeaderLabel(icon: "rectangle.3.group", title: "area.details".localized)

            VStack(spacing: AppTheme.Spacing.m) {
                themedTextField("area.name".localized, text: $name, placeholder: "area.namePlaceholder".localized)

                themedTextField("area.description".localized, text: $description, placeholder: "area.descriptionPlaceholder".localized)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("area.sortOrder".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    TextField("0", text: $sortOrder)
                        .keyboardType(.numberPad)
                        .padding(AppTheme.Spacing.m)
                        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                }
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
            .background(isFormValid ? AppTheme.themeColor : AppTheme.themeColor.opacity(0.4))
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
        let order = Int(sortOrder)

        await viewModel.createArea(
            departmentId: departmentId,
            name: trimmedName,
            description: trimmedDesc.isEmpty ? nil : trimmedDesc,
            category: selectedCategory?.rawValue,
            sortOrder: order
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
