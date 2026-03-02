//
//  ReportDamageView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Report Damage View
//
// Volunteer-facing form for reporting equipment damage.
// Can be initialized with a specific equipment ID or with a full list to pick from.

import SwiftUI

struct ReportDamageView: View {
    var equipmentId: String?
    var equipmentName: String?
    var equipment: [AudioEquipmentItemModel] = []

    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = AudioDamageViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var selectedEquipmentId = ""
    @State private var description = ""
    @State private var selectedSeverity: AudioDamageSeverityItem = .minor
    @State private var showError = false
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Equipment card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        HStack(spacing: 8) {
                            Image(systemName: "speaker.wave.2")
                                .foregroundStyle(AppTheme.themeColor)
                            Text("EQUIPMENT")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

                        if let name = equipmentName {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                                Text("av.damage.equipment".localized)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                                Text(name)
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(.primary)
                            }
                        } else if !equipment.isEmpty {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                                Text("av.damage.selectEquipment".localized)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                                Picker("", selection: $selectedEquipmentId) {
                                    Text("av.damage.selectPlaceholder".localized).tag("")
                                    ForEach(equipment) { item in
                                        Text("\(item.name) (\(item.category.displayName))").tag(item.id)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.primary)
                            }
                        }
                    }
                    .cardPadding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .themedCard(scheme: colorScheme)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Damage Report card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(AppTheme.themeColor)
                            Text("DAMAGE REPORT")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("av.damage.description".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            TextEditor(text: $description)
                                .frame(minHeight: 120)
                                .padding(AppTheme.Spacing.s)
                                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("av.damage.severity".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

                            HStack(spacing: AppTheme.Spacing.m) {
                                ForEach(AudioDamageSeverityItem.allCases, id: \.self) { severity in
                                    Button {
                                        selectedSeverity = severity
                                        HapticManager.shared.lightTap()
                                    } label: {
                                        VStack(spacing: AppTheme.Spacing.xs) {
                                            Image(systemName: severity.icon)
                                                .font(.system(size: 24))
                                            Text(severity.displayName)
                                                .font(AppTheme.Typography.captionSmall).fontWeight(.medium)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, AppTheme.Spacing.m)
                                        .background(selectedSeverity == severity ? severity.color.opacity(0.12) : AppTheme.cardBackgroundSecondary(for: colorScheme))
                                        .foregroundStyle(selectedSeverity == severity ? severity.color : AppTheme.textSecondary(for: colorScheme))
                                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                                .strokeBorder(selectedSeverity == severity ? severity.color : .clear, lineWidth: 1.5)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .cardPadding()
                    .themedCard(scheme: colorScheme)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
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
            .navigationTitle("av.damage.report".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("av.damage.submit".localized) {
                        Task { await submit() }
                    }
                    .disabled(resolvedEquipmentId.isEmpty || description.isEmpty || viewModel.isSaving)
                }
            }
            .onChange(of: viewModel.error) { _, error in
                showError = error != nil
            }
            .alert("common.error".localized, isPresented: $showError) {
                Button("common.ok".localized) { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
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

    private var resolvedEquipmentId: String {
        equipmentId ?? selectedEquipmentId
    }

    private func submit() async {
        let success = await viewModel.reportDamage(
            equipmentId: resolvedEquipmentId,
            description: description,
            severity: selectedSeverity.rawValue
        )
        if success { dismiss() }
    }
}

#Preview("With Equipment Name") {
    ReportDamageView(
        equipmentId: "eq-1",
        equipmentName: "Loudspeaker 1"
    )
    .environmentObject(AppState.shared)
}

#Preview("Pick from List") {
    ReportDamageView()
        .environmentObject(AppState.shared)
}

#Preview("Dark Mode") {
    ReportDamageView(
        equipmentId: "eq-1",
        equipmentName: "Loudspeaker 1"
    )
    .environmentObject(AppState.shared)
    .preferredColorScheme(.dark)
}
