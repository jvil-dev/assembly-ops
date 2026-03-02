//
//  CreateEquipmentSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Create Equipment Sheet
//
// Form for adding a single equipment item.
// Fields: name, model, serial, category, condition, location, notes.

import SwiftUI

struct CreateEquipmentSheet: View {
    @ObservedObject var viewModel: AudioEquipmentViewModel
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var model = ""
    @State private var serialNumber = ""
    @State private var selectedCategory: AudioEquipmentCategoryItem = .loudspeaker
    @State private var selectedCondition: AudioEquipmentConditionItem = .good
    @State private var location = ""
    @State private var notes = ""
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Item Details card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(AppTheme.themeColor)
                            Text("ITEM DETAILS")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

                        formField("av.equipment.name".localized, text: $name)

                        HStack(spacing: AppTheme.Spacing.m) {
                            formField("av.equipment.model".localized, text: $model)
                            formField("av.equipment.serial".localized, text: $serialNumber)
                        }
                    }
                    .cardPadding()
                    .themedCard(scheme: colorScheme)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Classification card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        HStack(spacing: 8) {
                            Image(systemName: "tag")
                                .foregroundStyle(AppTheme.themeColor)
                            Text("CLASSIFICATION")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("av.equipment.category".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            Picker("", selection: $selectedCategory) {
                                ForEach(Array(AudioEquipmentCategoryItem.audioRelevantCategories).sorted(by: { $0.displayName < $1.displayName }), id: \.self) { cat in
                                    Label(cat.displayName, systemImage: cat.icon).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.primary)
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("av.equipment.condition".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            Picker("", selection: $selectedCondition) {
                                ForEach(AudioEquipmentConditionItem.allCases, id: \.self) { cond in
                                    Text(cond.displayName).tag(cond)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .cardPadding()
                    .themedCard(scheme: colorScheme)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // Additional Info card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        HStack(spacing: 8) {
                            Image(systemName: "text.alignleft")
                                .foregroundStyle(AppTheme.themeColor)
                            Text("ADDITIONAL INFO")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

                        formField("av.equipment.location".localized, text: $location)

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("av.equipment.notes".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            TextEditor(text: $notes)
                                .frame(minHeight: 80)
                                .padding(AppTheme.Spacing.s)
                                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                        }
                    }
                    .cardPadding()
                    .themedCard(scheme: colorScheme)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("av.equipment.create".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("av.equipment.save".localized) {
                        Task { await save() }
                    }
                    .disabled(name.isEmpty || viewModel.isSaving)
                }
            }
            .overlay {
                if viewModel.isSaving {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                }
            }
        }
    }

    private func save() async {
        guard let eventId = sessionState.selectedEvent?.id else { return }
        let success = await viewModel.createEquipment(
            eventId: eventId,
            name: name,
            category: selectedCategory.rawValue,
            condition: selectedCondition.rawValue,
            model: model.isEmpty ? nil : model,
            serialNumber: serialNumber.isEmpty ? nil : serialNumber,
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes
        )
        if success { dismiss() }
    }

    private func formField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            TextField(label, text: text)
                .textFieldStyle(.plain)
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
    }
}

#Preview {
    CreateEquipmentSheet(viewModel: AudioEquipmentViewModel())
}

#Preview("Dark Mode") {
    CreateEquipmentSheet(viewModel: AudioEquipmentViewModel())
        .preferredColorScheme(.dark)
}
