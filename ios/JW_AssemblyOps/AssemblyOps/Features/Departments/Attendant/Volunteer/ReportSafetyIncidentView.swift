//
//  ReportSafetyIncidentView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/16/26.
//

// MARK: - Report Safety Incident View
//
// Form for attendant volunteers to report a safety incident.
// Grouped into themed cards: incident type, details, location.
//

import SwiftUI

struct ReportSafetyIncidentView: View {
    var posts: [AttendantPostItem] = []
    var currentSessionId: String?
    var onDidReport: (() async -> Void)?
    @StateObject private var viewModel = AttendantVolunteerViewModel()
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false

    // Form state
    @State private var selectedType: SafetyIncidentTypeItem = .other
    @State private var description = ""
    @State private var selectedPostId: String?
    @State private var customLocation = ""
    @State private var useCustomLocation = false
    @State private var didReport = false
    @State private var showError = false
    @State private var showProtocolCard = false

    /// Resolved location string for the API
    private var resolvedLocation: String? {
        if useCustomLocation {
            let trimmed = customLocation.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        } else if let postId = selectedPostId, let post = posts.first(where: { $0.id == postId }) {
            return [post.name, post.location].compactMap { $0 }.joined(separator: " — ")
        }
        return nil
    }

    var isFormValid: Bool {
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    incidentTypeCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    detailsCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    locationCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.10)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("attendant.incidents.report".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) {
                        Task {
                            guard let eventId = appState.currentEventId else { return }
                            await viewModel.reportIncident(
                                eventId: eventId,
                                type: selectedType.rawValue,
                                description: description,
                                location: resolvedLocation,
                                postId: selectedPostId,
                                sessionId: currentSessionId
                            )
                            if viewModel.error == nil {
                                if selectedType.requiresProtocolCard {
                                    showProtocolCard = true
                                } else {
                                    didReport = true
                                }
                            }
                        }
                    }
                    .disabled(!isFormValid || viewModel.isSaving)
                }
            }
            .alert("attendant.incidents.report.success".localized, isPresented: $didReport) {
                Button("common.ok".localized) {
                    HapticManager.shared.success()
                    Task {
                        await onDidReport?()
                        dismiss()
                    }
                }
            }
            .onChange(of: viewModel.error) { _, newValue in showError = newValue != nil }
            .alert("common.error".localized, isPresented: $showError) {
                Button("common.ok".localized) { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
            .fullScreenCover(isPresented: $showProtocolCard) {
                IncidentProtocolView(incidentType: selectedType) {
                    showProtocolCard = false
                    HapticManager.shared.success()
                    Task {
                        await onDidReport?()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Incident Type Card

    private var incidentTypeCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "exclamationmark.triangle", title: "attendant.incidents.section.incidentType".localized)

            VStack(spacing: AppTheme.Spacing.s) {
                ForEach(SafetyIncidentTypeItem.allCases, id: \.self) { type in
                    Button {
                        selectedType = type
                        HapticManager.shared.lightTap()
                    } label: {
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundStyle(selectedType == type ? AppTheme.themeColor : AppTheme.textTertiary(for: colorScheme))
                                .frame(width: 24)
                            Text(type.displayName)
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.themeColor)
                            }
                        }
                        .padding(AppTheme.Spacing.m)
                        .background(
                            selectedType == type
                                ? AppTheme.themeColor.opacity(0.1)
                                : AppTheme.cardBackgroundSecondary(for: colorScheme)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "text.alignleft", title: "attendant.incidents.section.details".localized)

            // Description (required)
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack(spacing: 2) {
                    Text("attendant.incidents.description".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Text("*")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.red)
                }

                ZStack(alignment: .topLeading) {
                    if description.isEmpty {
                        Text("attendant.incidents.description.placeholder".localized)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            .padding(.horizontal, AppTheme.Spacing.xs)
                            .padding(.vertical, AppTheme.Spacing.s)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $description)
                        .scrollContentBackground(.hidden)
                        .font(AppTheme.Typography.body)
                        .frame(minHeight: 80)
                }
                .padding(AppTheme.Spacing.s)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Location Card

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "mappin", title: "attendant.incidents.section.location".localized)

            locationPicker
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Location Picker

    private var locationPicker: some View {
        CategoryGroupedLocationPicker(
            posts: posts,
            selectedPostId: $selectedPostId,
            useCustomLocation: $useCustomLocation,
            customLocation: $customLocation
        )
    }
}

#Preview {
    ReportSafetyIncidentView()
        .environmentObject(AppState.shared)
}
