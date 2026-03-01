//
//  ResolveDamageSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Resolve Damage Sheet
//
// Simple form for entering resolution notes and marking a damage report resolved.

import SwiftUI

struct ResolveDamageSheet: View {
    let report: AudioDamageReportItem
    @ObservedObject var viewModel: AudioDamageViewModel
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var resolutionNotes = ""
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Report info card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        HStack(spacing: AppTheme.Spacing.s) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(report.severity.color)
                            Text("av.damage.reportInfo".localized.uppercased())
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

                        Text(report.equipmentName)
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(.primary)

                        Text(report.description)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                        HStack {
                            Text(report.severity.displayName)
                                .font(AppTheme.Typography.captionSmall).fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(report.severity.color.opacity(0.12))
                                .foregroundStyle(report.severity.color)
                                .clipShape(Capsule())
                            Spacer()
                            Text(report.reportedByName)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }
                    }
                    .cardPadding()
                    .themedCard(scheme: colorScheme)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Resolution card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal")
                                .foregroundStyle(AppTheme.themeColor)
                            Text("RESOLUTION")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("av.damage.resolutionNotes".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            TextEditor(text: $resolutionNotes)
                                .frame(minHeight: 120)
                                .padding(AppTheme.Spacing.s)
                                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
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
            .navigationTitle("av.damage.resolve".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("av.damage.markResolved".localized) {
                        Task { await resolve() }
                    }
                    .disabled(viewModel.isSaving)
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

    private func resolve() async {
        guard let eventId = sessionState.selectedEvent?.id else { return }
        let success = await viewModel.resolveDamage(
            id: report.id,
            resolutionNotes: resolutionNotes.isEmpty ? nil : resolutionNotes,
            eventId: eventId
        )
        if success { dismiss() }
    }
}

#Preview {
    ResolveDamageSheet(
        report: AudioDamageReportItem(
            id: "preview",
            equipmentId: "eq-1",
            equipmentName: "Loudspeaker 1",
            equipmentCategory: .loudspeaker,
            description: "Cracked housing on left side",
            severity: .moderate,
            reportedByName: "John Doe",
            sessionName: "Morning",
            resolved: false,
            resolvedAt: nil,
            resolvedByName: nil,
            resolutionNotes: nil,
            createdAt: Date()
        ),
        viewModel: AudioDamageViewModel()
    )
}

#Preview("Dark Mode") {
    ResolveDamageSheet(
        report: AudioDamageReportItem(
            id: "preview",
            equipmentId: "eq-1",
            equipmentName: "Loudspeaker 1",
            equipmentCategory: .loudspeaker,
            description: "Cracked housing on left side",
            severity: .severe,
            reportedByName: "John Doe",
            sessionName: nil,
            resolved: false,
            resolvedAt: nil,
            resolvedByName: nil,
            resolutionNotes: nil,
            createdAt: Date()
        ),
        viewModel: AudioDamageViewModel()
    )
    .preferredColorScheme(.dark)
}
