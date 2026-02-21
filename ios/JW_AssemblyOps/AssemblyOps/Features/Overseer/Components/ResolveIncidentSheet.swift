//
//  ResolveIncidentSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/16/26.
//

// MARK: - Resolve Incident Sheet
//
// Modal for resolving a safety incident with optional notes.
// Shows incident details (read-only) and resolution notes text editor.
//

import SwiftUI

struct ResolveIncidentSheet: View {
    let incident: SafetyIncidentItem
    @StateObject private var viewModel = SafetyIncidentViewModel()
    @ObservedObject private var sessionState = OverseerSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false
    @State private var resolutionNotes = ""
    @State private var didResolve = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Incident details (read-only)
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        HStack(spacing: 8) {
                            Image(systemName: incident.type.icon)
                                .foregroundStyle(AppTheme.StatusColors.warning)
                            Text(incident.type.displayName)
                                .font(AppTheme.Typography.headline)
                        }

                        Text(incident.description)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                        if let location = incident.location {
                            Label(location, systemImage: "mappin")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

                        if let postName = incident.postName {
                            Label(postName, systemImage: "map")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

                        HStack {
                            Text(String(format: "attendant.volunteer.reportedBy".localized, incident.reportedByName))
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            Spacer()
                            Text(DateUtils.timeAgo(from: incident.createdAt))
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }
                    }
                    .cardPadding()
                    .themedCard(scheme: colorScheme)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Resolution notes
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                        SectionHeaderLabel(icon: "note.text", title: "attendant.incidents.notes".localized)

                        TextEditor(text: $resolutionNotes)
                            .frame(minHeight: 100)
                            .padding(AppTheme.Spacing.s)
                            .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                            .cornerRadius(AppTheme.CornerRadius.small)
                    }
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("attendant.incidents.resolve".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("attendant.incidents.resolve".localized) {
                        Task {
                            if let eventId = sessionState.selectedEvent?.id {
                                let notes = resolutionNotes.isEmpty ? nil : resolutionNotes
                                await viewModel.resolveIncident(id: incident.id, notes: notes, eventId: eventId)
                                didResolve = true
                            }
                        }
                    }
                }
            }
            .alert("common.success".localized, isPresented: $didResolve) {
                Button("common.ok".localized) { dismiss() }
            } message: {
                Text("attendant.incidents.resolved".localized)
            }
            .alert("common.error".localized, isPresented: .constant(viewModel.error != nil)) {
                Button("common.ok".localized) { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }
}
