//
//  CreatePostSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/14/26.
//

// MARK: - Create Post Sheet
//
// Modal sheet for creating new posts within a department.
// Supports both single post and bulk creation modes.
//
// Features:
//   - Single/Bulk segmented picker
//   - Single mode: name, optional description/location/category
//   - Bulk mode: prefix, start number, count, optional category
//   - Preview of generated names in bulk mode
//   - Creates post(s) in current department context
//
// Navigation:
//   - Presented as sheet from SessionDetailView
//   - Dismisses after successful creation

import SwiftUI

struct CreatePostSheet: View {
    let categorySuggestions: [String]
    let locationSuggestions: [String]
    var preselectedCategory: AttendantMainCategory? = nil

    /// When creating a post inside an area, pass the area context
    var areaId: String? = nil
    var areaCategory: String? = nil

    @StateObject private var viewModel = PostsViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false
    @State private var isBulkMode = false
    @State private var createdPostName = ""
    @State private var createdBulkCount = 0

    // Attendant category picker state
    @State private var selectedMain: AttendantMainCategory? = nil
    @State private var selectedSub: String? = nil
    @State private var customSub: String = ""
    @State private var showCustomSub = false

    private var isAttendant: Bool {
        sessionState.selectedDepartment?.departmentType == "ATTENDANT"
    }

    private var departmentType: String {
        sessionState.selectedDepartment?.departmentType ?? "DEFAULT"
    }

    private var departmentColor: Color {
        DepartmentColor.color(for: departmentType)
    }

    /// When inside an area, determine the main category from the area's category string
    private var areaMainCategory: AttendantMainCategory? {
        guard let cat = areaCategory else { return nil }
        return AttendantMainCategory.mainCategory(from: cat)
    }

    /// Whether this sheet was opened from within an area (category derived from area)
    private var isAreaContext: Bool { areaId != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    modePicker
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    if isBulkMode {
                        bulkSettingsCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                        if !viewModel.bulkPreviewNames.isEmpty {
                            bulkPreviewCard
                                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                        }
                    } else {
                        requiredCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                        optionalCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                    }
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("post.create".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) {
                        Task {
                            guard let departmentId = sessionState.selectedDepartment?.id else { return }
                            if isBulkMode {
                                createdBulkCount = viewModel.bulkPreviewNames.count
                                await viewModel.createBulkPosts(departmentId: departmentId)
                            } else {
                                createdPostName = viewModel.name
                                await viewModel.createPost(departmentId: departmentId)
                            }
                        }
                    }
                    .disabled(isBulkMode
                        ? !viewModel.isBulkFormValid || viewModel.isSaving
                        : !viewModel.isFormValid || viewModel.isSaving
                    )
                }
            }
            .alert("post.created".localized, isPresented: $viewModel.didCreate) {
                Button("common.ok".localized) { dismiss() }
            } message: {
                if isBulkMode {
                    Text("post.bulkCreatedMessage".localized(with: "\(createdBulkCount)"))
                } else {
                    Text("post.createdMessage".localized(with: createdPostName))
                }
            }
            .alert("common.error".localized, isPresented: .constant(viewModel.error != nil)) {
                Button("common.ok".localized) { viewModel.error = nil }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
            .onAppear {
                // Set area context on the view model
                viewModel.areaId = areaId

                if isAreaContext, let areaCat = areaMainCategory {
                    // Area context: set main category from area, only allow subcategory
                    selectedMain = areaCat
                    syncCategory()
                } else if let preselected = preselectedCategory {
                    selectedMain = preselected
                    syncCategory()
                }
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        Picker("", selection: $isBulkMode.animation()) {
            Text("post.single".localized).tag(false)
            Text("post.bulkAdd".localized).tag(true)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Single Mode: Required Card

    private var requiredCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "mappin.circle.fill", title: "REQUIRED")

            VStack(spacing: AppTheme.Spacing.m) {
                themedTextField("post.name".localized, text: $viewModel.name)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Single Mode: Optional Card

    private var optionalCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "info.circle", title: "OPTIONAL")

            VStack(spacing: AppTheme.Spacing.m) {
                if isAttendant && !isAreaContext {
                    // Full I/E/S category picker when not inside an area
                    attendantCategoryPicker
                } else if isAreaContext, let areaCat = areaMainCategory, !areaCat.commonSubcategories.isEmpty {
                    // Subcategory-only picker for Exterior areas
                    attendantSubcategoryPicker(for: areaCat)
                } else if !isAttendant {
                    SuggestionTextField(
                        placeholder: "post.category".localized,
                        text: $viewModel.category,
                        suggestions: categorySuggestions,
                        colorScheme: colorScheme
                    )
                }

                themedTextField("post.description".localized, text: $viewModel.description)

                SuggestionTextField(
                    placeholder: "post.location".localized,
                    text: $viewModel.location,
                    suggestions: locationSuggestions,
                    colorScheme: colorScheme
                )
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Bulk Mode: Settings Card

    private var bulkSettingsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "square.grid.3x3.fill", title: "post.bulkSettings".localized.uppercased())

            VStack(spacing: AppTheme.Spacing.m) {
                themedTextField("post.bulkPrefix".localized, text: $viewModel.bulkPrefix)

                HStack(spacing: AppTheme.Spacing.m) {
                    themedTextField("post.bulkStartNumber".localized, text: $viewModel.bulkStartNumber)
                        .keyboardType(.numberPad)

                    themedTextField("post.bulkCount".localized, text: $viewModel.bulkCount)
                        .keyboardType(.numberPad)
                }

                if isAttendant && !isAreaContext {
                    attendantCategoryPicker
                } else if isAreaContext, let areaCat = areaMainCategory, !areaCat.commonSubcategories.isEmpty {
                    attendantSubcategoryPicker(for: areaCat)
                } else if !isAttendant {
                    SuggestionTextField(
                        placeholder: "post.category".localized,
                        text: $viewModel.category,
                        suggestions: categorySuggestions,
                        colorScheme: colorScheme
                    )
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Bulk Mode: Preview Card

    private var bulkPreviewCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "eye", title: "post.bulkPreview".localized.uppercased())

            let names = viewModel.bulkPreviewNames
            let displayNames = names.count > 6
                ? names.prefix(3) + ["..."] + names.suffix(3)
                : Array(names)

            Text(displayNames.joined(separator: ", "))
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            HStack {
                Image(systemName: "number")
                    .foregroundStyle(AppTheme.themeColor)
                Text("\(names.count) " + "post.postsTotal".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Attendant Category Picker

    private var attendantCategoryPicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            Text("post.category".localized)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            // Step 1: Main category pills (I / E / S)
            HStack(spacing: AppTheme.Spacing.s) {
                ForEach(AttendantMainCategory.allCases) { main in
                    Button {
                        if selectedMain == main {
                            selectedMain = nil
                            selectedSub = nil
                            showCustomSub = false
                            customSub = ""
                            viewModel.category = ""
                        } else {
                            selectedMain = main
                            selectedSub = nil
                            showCustomSub = false
                            customSub = ""
                            syncCategory()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(main.code)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                            Text(main.rawValue)
                                .font(AppTheme.Typography.caption)
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)
                        .padding(.vertical, AppTheme.Spacing.s)
                        .background(selectedMain == main
                            ? departmentColor
                            : AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .foregroundStyle(selectedMain == main ? .white : AppTheme.textSecondary(for: colorScheme))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            // Step 2: Subcategory chips (only for Exterior)
            if let main = selectedMain, !main.commonSubcategories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.s) {
                        ForEach(main.commonSubcategories, id: \.self) { sub in
                            Button {
                                selectedSub = sub
                                showCustomSub = false
                                customSub = ""
                                syncCategory()
                            } label: {
                                Text(sub)
                                    .font(AppTheme.Typography.caption)
                                    .padding(.horizontal, AppTheme.Spacing.m)
                                    .padding(.vertical, AppTheme.Spacing.s)
                                    .background(selectedSub == sub
                                        ? departmentColor.opacity(0.2)
                                        : AppTheme.cardBackgroundSecondary(for: colorScheme))
                                    .foregroundStyle(selectedSub == sub
                                        ? departmentColor
                                        : AppTheme.textSecondary(for: colorScheme))
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(selectedSub == sub
                                                ? departmentColor
                                                : Color.clear, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        // Custom chip
                        Button {
                            selectedSub = nil
                            showCustomSub = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Custom")
                                    .font(AppTheme.Typography.caption)
                            }
                            .padding(.horizontal, AppTheme.Spacing.m)
                            .padding(.vertical, AppTheme.Spacing.s)
                            .background(showCustomSub
                                ? departmentColor.opacity(0.2)
                                : AppTheme.cardBackgroundSecondary(for: colorScheme))
                            .foregroundStyle(showCustomSub
                                ? departmentColor
                                : AppTheme.textSecondary(for: colorScheme))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(showCustomSub
                                        ? departmentColor
                                        : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Custom subcategory text field
                if showCustomSub {
                    TextField("e.g. Gate, Ramp B", text: $customSub)
                        .padding(AppTheme.Spacing.m)
                        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                        .onChange(of: customSub) { _, value in
                            syncCategory()
                        }
                }
            }
        }
    }

    /// Subcategory-only picker shown when creating a post inside an Exterior area
    private func attendantSubcategoryPicker(for main: AttendantMainCategory) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            Text("post.subcategory".localized)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.s) {
                    ForEach(main.commonSubcategories, id: \.self) { sub in
                        Button {
                            selectedSub = sub
                            showCustomSub = false
                            customSub = ""
                            syncCategory()
                        } label: {
                            Text(sub)
                                .font(AppTheme.Typography.caption)
                                .padding(.horizontal, AppTheme.Spacing.m)
                                .padding(.vertical, AppTheme.Spacing.s)
                                .background(selectedSub == sub
                                    ? departmentColor.opacity(0.2)
                                    : AppTheme.cardBackgroundSecondary(for: colorScheme))
                                .foregroundStyle(selectedSub == sub
                                    ? departmentColor
                                    : AppTheme.textSecondary(for: colorScheme))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(selectedSub == sub
                                            ? departmentColor
                                            : Color.clear, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    // Custom chip
                    Button {
                        selectedSub = nil
                        showCustomSub = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Custom")
                                .font(AppTheme.Typography.caption)
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)
                        .padding(.vertical, AppTheme.Spacing.s)
                        .background(showCustomSub
                            ? departmentColor.opacity(0.2)
                            : AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .foregroundStyle(showCustomSub
                            ? departmentColor
                            : AppTheme.textSecondary(for: colorScheme))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(showCustomSub
                                    ? departmentColor
                                    : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if showCustomSub {
                TextField("e.g. Gate, Ramp B", text: $customSub)
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    .onChange(of: customSub) { _, value in
                        syncCategory()
                    }
            }
        }
    }

    private func syncCategory() {
        guard let main = selectedMain else {
            viewModel.category = ""
            return
        }
        let sub: String?
        if showCustomSub {
            sub = customSub.isEmpty ? nil : customSub
        } else {
            sub = selectedSub
        }
        viewModel.category = AttendantMainCategory.storageString(main: main, sub: sub)
    }

    // MARK: - Helpers

    private func themedTextField(
        _ label: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            TextField("", text: text)
                .keyboardType(keyboardType)
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
    }
}

#Preview {
    CreatePostSheet(
        categorySuggestions: ["Seating", "Doors", "Exits"],
        locationSuggestions: ["Main Floor", "Balcony", "Lobby"]
    )
}
