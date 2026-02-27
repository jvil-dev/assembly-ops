//
//  CreateFacilityLocationSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

import SwiftUI

struct CreateFacilityLocationSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var appState: AppState

    var onCreated: (FacilityLocationItem) -> Void

    @State private var name = ""
    @State private var location = ""
    @State private var description = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !location.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        SectionHeaderLabel(icon: "building.2", title: "attendant.facility.create".localized)

                        TextField("attendant.facility.name".localized, text: $name)
                            .font(AppTheme.Typography.body)
                            .padding(AppTheme.Spacing.m)
                            .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

                        TextField("attendant.facility.location".localized, text: $location)
                            .font(AppTheme.Typography.body)
                            .padding(AppTheme.Spacing.m)
                            .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

                        TextField("attendant.facility.description".localized, text: $description, axis: .vertical)
                            .font(AppTheme.Typography.body)
                            .lineLimit(3...6)
                            .padding(AppTheme.Spacing.m)
                            .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    }
                    .cardPadding()
                    .themedCard(scheme: colorScheme)

                    Button {
                        Task { await save() }
                    } label: {
                        HStack(spacing: AppTheme.Spacing.s) {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                Text("attendant.facility.create".localized)
                            }
                        }
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.m)
                        .background(isValid && !isSaving ? AppTheme.themeColor : AppTheme.textTertiary(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isValid || isSaving)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("attendant.facility.create".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
            }
            .alert("common.error".localized, isPresented: $showError) {
                Button("common.ok".localized) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func save() async {
        guard let eventId = EventSessionState.shared.selectedEvent?.id else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let item = try await AttendantService.shared.createFacilityLocation(
                eventId: eventId,
                name: name.trimmingCharacters(in: .whitespaces),
                location: location.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description.trimmingCharacters(in: .whitespaces),
                sortOrder: nil
            )
            HapticManager.shared.success()
            onCreated(item)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.shared.error()
        }
    }
}
