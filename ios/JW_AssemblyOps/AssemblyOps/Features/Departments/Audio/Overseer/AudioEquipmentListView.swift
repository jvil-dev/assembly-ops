//
//  AudioEquipmentListView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - AV Equipment List View
//
// Filterable list of equipment items. Supports category filter and search.
// Tap item → AudioEquipmentDetailView.
// Add button → CreateEquipmentSheet or BulkCreateEquipmentSheet.

import SwiftUI

struct AudioEquipmentListView: View {
    @StateObject private var viewModel = AudioEquipmentViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showCreateSheet = false
    @State private var showBulkCreateSheet = false
    @State private var showError = false

    private var accentColor: Color {
        if let deptType = sessionState.selectedDepartment?.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Category filter
                categoryFilterRow
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                // Equipment list
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.filteredEquipment.isEmpty {
                    emptyState
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                } else {
                    LazyVStack(spacing: AppTheme.Spacing.m) {
                        ForEach(Array(viewModel.filteredEquipment.enumerated()), id: \.element.id) { index, item in
                            NavigationLink(destination: AudioEquipmentDetailView(equipmentId: item.id)) {
                                equipmentRow(item)
                            }
                            .buttonStyle(.plain)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.02 + 0.05)
                        }
                    }
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("av.equipment.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "av.equipment.search".localized)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showCreateSheet = true
                        HapticManager.shared.lightTap()
                    } label: {
                        Label("av.equipment.addOne".localized, systemImage: "plus")
                    }
                    Button {
                        showBulkCreateSheet = true
                        HapticManager.shared.lightTap()
                    } label: {
                        Label("av.equipment.addBulk".localized, systemImage: "plus.rectangle.on.rectangle")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateEquipmentSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showBulkCreateSheet) {
            BulkCreateEquipmentSheet(viewModel: viewModel)
        }
        .onChange(of: viewModel.error) { _, error in
            showError = error != nil
        }
        .alert("common.error".localized, isPresented: $showError) {
            Button("common.ok".localized) { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .refreshable {
            if let eventId = sessionState.selectedEvent?.id {
                await viewModel.loadEquipment(eventId: eventId)
            }
        }
        .task {
            if let eventId = sessionState.selectedEvent?.id {
                await viewModel.loadEquipment(eventId: eventId)
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Category Filter

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.s) {
                filterChip(label: "av.equipment.filter.all".localized, isSelected: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                }
                ForEach(Array(AudioEquipmentCategoryItem.audioRelevantCategories).sorted(by: { $0.displayName < $1.displayName }), id: \.self) { category in
                    filterChip(label: category.displayName, isSelected: viewModel.selectedCategory == category) {
                        viewModel.selectedCategory = category
                    }
                }
            }
        }
    }

    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            HapticManager.shared.lightTap()
        } label: {
            Text(label)
                .font(AppTheme.Typography.caption).fontWeight(.medium)
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.vertical, AppTheme.Spacing.s)
                .background(isSelected ? accentColor.opacity(0.15) : AppTheme.cardBackground(for: colorScheme))
                .foregroundStyle(isSelected ? accentColor : AppTheme.textSecondary(for: colorScheme))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Equipment Row

    private func equipmentRow(_ item: AudioEquipmentItemModel) -> some View {
        HStack(spacing: AppTheme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(item.condition.color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: item.category.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(item.condition.color)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(item.name)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: AppTheme.Spacing.s) {
                    Text(item.category.displayName)
                        .font(AppTheme.Typography.captionSmall)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

                    if item.currentCheckout != nil {
                        Text("av.equipment.checkedOut".localized)
                            .font(AppTheme.Typography.captionSmall).fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.StatusColors.pendingBackground)
                            .foregroundStyle(AppTheme.StatusColors.pending)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Image(systemName: item.condition.icon)
                .foregroundStyle(item.condition.color)
                .font(.system(size: 14))

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "shippingbox")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Text("av.equipment.empty".localized)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            Text("av.equipment.emptyHint".localized)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxl)
    }
}

#Preview {
    NavigationStack {
        AudioEquipmentListView()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        AudioEquipmentListView()
    }
    .preferredColorScheme(.dark)
}
