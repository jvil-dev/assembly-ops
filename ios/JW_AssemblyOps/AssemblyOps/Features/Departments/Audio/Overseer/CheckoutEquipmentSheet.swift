//
//  CheckoutEquipmentSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Checkout Equipment Sheet
//
// Form for checking out equipment to a volunteer.
// Requires selecting a volunteer and optionally a session.

import SwiftUI

struct CheckoutEquipmentSheet: View {
    let equipmentId: String
    let equipmentName: String
    var onComplete: (() async -> Void)?

    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var selectedVolunteerId = ""
    @State private var selectedSessionId = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var error: String?
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

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("av.checkout.equipment".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            Text(equipmentName)
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(.primary)
                        }
                    }
                    .cardPadding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .themedCard(scheme: colorScheme)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Assignment card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.key")
                                .foregroundStyle(AppTheme.themeColor)
                            Text("ASSIGNMENT")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("av.checkout.volunteer".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            TextField("av.checkout.volunteerId".localized, text: $selectedVolunteerId)
                                .textFieldStyle(.plain)
                                .padding(AppTheme.Spacing.m)
                                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("av.checkout.session".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            TextField("av.checkout.sessionOptional".localized, text: $selectedSessionId)
                                .textFieldStyle(.plain)
                                .padding(AppTheme.Spacing.m)
                                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("av.checkout.notes".localized)
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
            .navigationTitle("av.checkout.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("av.checkout.confirm".localized) {
                        Task { await checkout() }
                    }
                    .disabled(selectedVolunteerId.isEmpty || isSaving)
                }
            }
            .onChange(of: error) { _, err in
                showError = err != nil
            }
            .alert("common.error".localized, isPresented: $showError) {
                Button("common.ok".localized) { error = nil }
            } message: {
                Text(error ?? "")
            }
            .overlay {
                if isSaving {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                }
            }
        }
    }

    private func checkout() async {
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await AudioVideoService.shared.checkoutEquipment(
                equipmentId: equipmentId,
                checkedOutById: selectedVolunteerId,
                sessionId: selectedSessionId.isEmpty ? nil : selectedSessionId,
                notes: notes.isEmpty ? nil : notes
            )
            HapticManager.shared.success()
            dismiss()
            await onComplete?()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }
}

#Preview {
    CheckoutEquipmentSheet(
        equipmentId: "preview-id",
        equipmentName: "Loudspeaker 1"
    )
}

#Preview("Dark Mode") {
    CheckoutEquipmentSheet(
        equipmentId: "preview-id",
        equipmentName: "Loudspeaker 1"
    )
    .preferredColorScheme(.dark)
}
