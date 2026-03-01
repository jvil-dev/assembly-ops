//
//  CreateVideoHazardAssessmentSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Create Video Hazard Assessment Sheet
//
// Form for creating a Job Hazard Analysis (JHA) for the video crew.
// Fields: title, hazard type, description, controls, PPE multi-select.

import SwiftUI

struct CreateVideoHazardAssessmentSheet: View {
    @ObservedObject var viewModel: VideoSafetyViewModel
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var selectedHazardType: AudioHazardTypeItem = .electricalExposure
    @State private var description = ""
    @State private var controls = ""
    @State private var selectedPPE: Set<AudioPPEType> = []
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Hazard Info card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(AppTheme.themeColor)
                            Text("HAZARD INFO")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

                        formField("av.hazard.create.title".localized, text: $title)

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("av.hazard.type".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            Picker("", selection: $selectedHazardType) {
                                ForEach(AudioHazardTypeItem.allCases, id: \.self) { type in
                                    Label(type.displayName, systemImage: type.icon).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.primary)
                        }
                    }
                    .cardPadding()
                    .themedCard(scheme: colorScheme)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Analysis card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundStyle(AppTheme.themeColor)
                            Text("ANALYSIS")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("av.hazard.description".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            TextEditor(text: $description)
                                .frame(minHeight: 80)
                                .padding(AppTheme.Spacing.s)
                                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("av.hazard.controls".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            TextEditor(text: $controls)
                                .frame(minHeight: 80)
                                .padding(AppTheme.Spacing.s)
                                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                        }
                    }
                    .cardPadding()
                    .themedCard(scheme: colorScheme)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // PPE Requirements card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        HStack(spacing: 8) {
                            Image(systemName: "shield.checkered")
                                .foregroundStyle(AppTheme.themeColor)
                            Text("PPE REQUIREMENTS")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

                        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: AppTheme.Spacing.s) {
                            ForEach(AudioPPEType.allCases, id: \.self) { ppe in
                                Button {
                                    if selectedPPE.contains(ppe) {
                                        selectedPPE.remove(ppe)
                                    } else {
                                        selectedPPE.insert(ppe)
                                    }
                                    HapticManager.shared.lightTap()
                                } label: {
                                    HStack(spacing: AppTheme.Spacing.s) {
                                        Image(systemName: ppe.icon)
                                            .font(.system(size: 14))
                                        Text(ppe.displayName)
                                            .font(AppTheme.Typography.caption)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(AppTheme.Spacing.m)
                                    .background(selectedPPE.contains(ppe) ? AppTheme.themeColor.opacity(0.12) : AppTheme.cardBackgroundSecondary(for: colorScheme))
                                    .foregroundStyle(selectedPPE.contains(ppe) ? AppTheme.themeColor : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                            .strokeBorder(selectedPPE.contains(ppe) ? AppTheme.themeColor : .clear, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
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
            .navigationTitle("av.hazard.create".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("av.hazard.save".localized) {
                        Task { await save() }
                    }
                    .disabled(title.isEmpty || description.isEmpty || controls.isEmpty || viewModel.isSaving)
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
        let success = await viewModel.createHazardAssessment(
            eventId: eventId,
            title: title,
            hazardType: selectedHazardType.rawValue,
            description: description,
            controls: controls,
            ppeRequired: selectedPPE.map(\.rawValue)
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
    CreateVideoHazardAssessmentSheet(viewModel: VideoSafetyViewModel())
}

#Preview("Dark Mode") {
    CreateVideoHazardAssessmentSheet(viewModel: VideoSafetyViewModel())
        .preferredColorScheme(.dark)
}
