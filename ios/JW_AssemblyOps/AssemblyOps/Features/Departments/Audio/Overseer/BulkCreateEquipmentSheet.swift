//
//  BulkCreateEquipmentSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Bulk Create Equipment Sheet
//
// Template-based batch creation. Pick a category, specify count,
// and optionally set a naming pattern. Creates N items at once.

import SwiftUI

struct BulkCreateEquipmentSheet: View {
    @ObservedObject var viewModel: AudioEquipmentViewModel
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var selectedCategory: AudioEquipmentCategoryItem = .loudspeaker
    @State private var count = 1
    @State private var namePrefix = ""
    @State private var location = ""
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Template card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.stack.3d.up")
                                .foregroundStyle(AppTheme.themeColor)
                            Text("TEMPLATE")
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
                            Text("av.equipment.bulk.count".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            Stepper("\(count)", value: $count, in: 1...50)
                                .padding(AppTheme.Spacing.m)
                                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                        }
                    }
                    .cardPadding()
                    .themedCard(scheme: colorScheme)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Naming card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        HStack(spacing: 8) {
                            Image(systemName: "character.cursor.ibeam")
                                .foregroundStyle(AppTheme.themeColor)
                            Text("NAMING")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("av.equipment.bulk.prefix".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            TextField("av.equipment.bulk.prefixPlaceholder".localized, text: $namePrefix)
                                .textFieldStyle(.plain)
                                .padding(AppTheme.Spacing.m)
                                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                            Text("av.equipment.bulk.prefixHint".localized)
                                .font(AppTheme.Typography.captionSmall)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("av.equipment.location".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            TextField("av.equipment.location".localized, text: $location)
                                .textFieldStyle(.plain)
                                .padding(AppTheme.Spacing.m)
                                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                        }
                    }
                    .cardPadding()
                    .themedCard(scheme: colorScheme)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // Preview card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        HStack(spacing: 8) {
                            Image(systemName: "eye")
                                .foregroundStyle(AppTheme.themeColor)
                            Text("PREVIEW")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            ForEach(0..<min(count, 3), id: \.self) { i in
                                Text(itemName(index: i + 1))
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(.primary)
                            }
                            if count > 3 {
                                Text("... +\(count - 3) more")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            }
                        }
                        .cardPadding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
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
            .navigationTitle("av.equipment.bulk.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("av.equipment.bulk.create".localized) {
                        Task { await save() }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .overlay {
                if viewModel.isSaving {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("av.equipment.bulk.creating".localized)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                }
            }
        }
    }

    private func itemName(index: Int) -> String {
        let prefix = namePrefix.isEmpty ? selectedCategory.displayName : namePrefix
        return "\(prefix) \(index)"
    }

    private func save() async {
        guard let eventId = sessionState.selectedEvent?.id else { return }
        let items = (1...count).map { i in
            AssemblyOpsAPI.AVEquipmentItemInput(
                name: itemName(index: i),
                category: .init(rawValue: selectedCategory.rawValue),
                location: location.isEmpty ? .none : .some(location)
            )
        }
        let success = await viewModel.bulkCreateEquipment(eventId: eventId, items: items)
        if success { dismiss() }
    }
}

#Preview {
    BulkCreateEquipmentSheet(viewModel: AudioEquipmentViewModel())
}

#Preview("Dark Mode") {
    BulkCreateEquipmentSheet(viewModel: AudioEquipmentViewModel())
        .preferredColorScheme(.dark)
}
