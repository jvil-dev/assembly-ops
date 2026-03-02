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
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false
    @State private var resolutionNotes = ""
    @State private var didResolve = false
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    incidentDetailsCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    resolutionNotesCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("attendant.incidents.resolve".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { sheetToolbar }
            .alert("common.success".localized, isPresented: $didResolve) {
                Button("common.ok".localized) { dismiss() }
            } message: {
                Text("attendant.incidents.resolved".localized)
            }
            .alert("common.error".localized, isPresented: $showError) {
                Button("common.ok".localized) { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .onChange(of: viewModel.error) { _, newValue in showError = newValue != nil }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Incident Details Card

    private var incidentDetailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            incidentHeader
            incidentDescription
            incidentLocation
            incidentPost
            incidentReporter
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private var incidentHeader: some View {
        HStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: incident.type.icon)
                .foregroundStyle(AppTheme.StatusColors.warning)
            Text(incident.type.displayName)
                .font(AppTheme.Typography.headline)
        }
    }

    private var incidentDescription: some View {
        Text(incident.description)
            .font(AppTheme.Typography.body)
            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
    }

    @ViewBuilder
    private var incidentLocation: some View {
        if let location = incident.location {
            Label(location, systemImage: "mappin")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
        }
    }

    @ViewBuilder
    private var incidentPost: some View {
        if let postName = incident.postName {
            Label(postName, systemImage: "map")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
        }
    }

    private var incidentReporter: some View {
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

    // MARK: - Resolution Notes Card

    private var resolutionNotesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            SectionHeaderLabel(icon: "note.text", title: "attendant.incidents.notes".localized)

            TextEditor(text: $resolutionNotes)
                .frame(minHeight: 100)
                .padding(AppTheme.Spacing.s)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var sheetToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("common.cancel".localized) { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("attendant.incidents.resolve".localized) {
                Task {
                    let notes = resolutionNotes.isEmpty ? nil : resolutionNotes
                    await viewModel.resolveIncident(id: incident.id, resolutionNotes: notes)
                    if viewModel.error == nil {
                        didResolve = true
                    }
                }
            }
        }
    }
}

#Preview {
    ResolveIncidentSheet(
        incident: SafetyIncidentItem(
            id: "inc-1",
            type: .wetFloor,
            description: "Water spill near entrance hallway",
            location: "Main Lobby",
            postId: nil,
            postName: nil,
            reportedByName: "John Smith",
            resolved: false,
            resolvedAt: nil,
            resolvedByName: nil,
            resolutionNotes: nil,
            createdAt: Date()
        )
    )
}
