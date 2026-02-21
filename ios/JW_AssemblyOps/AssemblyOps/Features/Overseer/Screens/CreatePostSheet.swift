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

    @StateObject private var viewModel = PostsViewModel()
    @ObservedObject private var sessionState = OverseerSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false
    @State private var isBulkMode = false

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
                                await viewModel.createBulkPosts(departmentId: departmentId)
                            } else {
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
                    Text("post.bulkCreatedMessage".localized(with: "\(viewModel.bulkPreviewNames.count)"))
                } else {
                    Text("post.createdMessage".localized(with: viewModel.name))
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
                SuggestionTextField(
                    placeholder: "post.category".localized,
                    text: $viewModel.category,
                    suggestions: categorySuggestions,
                    colorScheme: colorScheme
                )

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

                SuggestionTextField(
                    placeholder: "post.category".localized,
                    text: $viewModel.category,
                    suggestions: categorySuggestions,
                    colorScheme: colorScheme
                )
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
