//
//  CreatePostSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/14/26.
//

// MARK: - Create Post Sheet
//
// Modal sheet for creating new posts within a department.
// Posts represent specific locations or positions that volunteers can be assigned to.
//
// Features:
//   - Post name input field
//   - Optional description field
//   - Form validation (name required)
//   - Creates post in current department context
//   - Success/error handling with alerts
//
// Navigation:
//   - Presented as sheet from department management screens
//   - Dismisses after successful creation

import SwiftUI

struct CreatePostSheet: View {
    @StateObject private var viewModel = PostsViewModel()
    @ObservedObject private var sessionState = OverseerSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    requiredCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    optionalCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    examplesCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
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
                            await viewModel.createPost(departmentId: departmentId)
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isSaving)
                }
            }
            .alert("post.created".localized, isPresented: $viewModel.didCreate) {
                Button("common.ok".localized) { dismiss() }
            } message: {
                Text("post.createdMessage".localized(with: viewModel.name))
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

    // MARK: - Required Card

    private var requiredCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            sectionHeader(icon: "mappin.circle.fill", title: "REQUIRED")

            VStack(spacing: AppTheme.Spacing.m) {
                themedTextField("post.name".localized, text: $viewModel.name)

                themedTextField("post.capacity".localized, text: $viewModel.capacityText)
                    .keyboardType(.numberPad)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Optional Card

    private var optionalCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            sectionHeader(icon: "info.circle", title: "OPTIONAL")

            VStack(spacing: AppTheme.Spacing.m) {
                themedTextField("post.description".localized, text: $viewModel.description)

                themedTextField("post.location".localized, text: $viewModel.location)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Examples Card

    private var examplesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            sectionHeader(icon: "lightbulb", title: "post.examples".localized.uppercased())

            Text("Name: Section 102 Attendant\nLocation: Section 102, Main Floor\nCapacity: 2")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            Divider()

            Text("Name: Sound Technician\nLocation: Sound Booth\nCapacity: 1")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.themeColor)
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
        }
    }

    private func themedTextField(
        _ placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboardType)
            .padding(AppTheme.Spacing.m)
            .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
    }
}

#Preview {
    CreatePostSheet()
}
