//
//  ResolveLostPersonSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/16/26.
//

// MARK: - Resolve Lost Person Sheet
//
// Modal for resolving a lost person alert with required notes.
// Shows alert details (read-only) and resolution notes text editor.
//

import SwiftUI

struct ResolveLostPersonSheet: View {
    let alert: LostPersonAlertItem
    @StateObject private var viewModel = LostPersonViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared
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
                    alertDetailsCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    resolutionNotesCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("attendant.lostPerson.resolve".localized)
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

    // MARK: - Alert Details Card

    private var alertDetailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            alertHeader
            alertDescription
            alertLocation
            alertContact
            alertReporter
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private var alertHeader: some View {
        HStack {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .foregroundStyle(.red)
            Text(alert.personName)
                .font(AppTheme.Typography.headline)
            if let age = alert.age {
                Text("(\(age))")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
    }

    private var alertDescription: some View {
        Text(alert.description)
            .font(AppTheme.Typography.body)
            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
    }

    @ViewBuilder
    private var alertLocation: some View {
        if let location = alert.lastSeenLocation {
            Label(location, systemImage: "mappin")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
        }
    }

    private var alertContact: some View {
        HStack {
            Label(alert.contactName, systemImage: "phone")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            if let phone = alert.contactPhone {
                Text(phone)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.themeColor)
            }
        }
    }

    private var alertReporter: some View {
        Text(String(format: "attendant.volunteer.reportedBy".localized, alert.reportedByName))
            .font(AppTheme.Typography.caption)
            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
    }

    // MARK: - Resolution Notes Card

    private var resolutionNotesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            SectionHeaderLabel(icon: "note.text", title: "attendant.lostPerson.resolutionNotes".localized)

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
            Button("attendant.lostPerson.resolve".localized) {
                Task {
                    await viewModel.resolveAlert(id: alert.id, resolutionNotes: resolutionNotes)
                    didResolve = true
                }
            }
            .disabled(resolutionNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

#Preview {
    ResolveLostPersonSheet(
        alert: LostPersonAlertItem(
            id: "lp-1",
            personName: "Maria Garcia",
            age: 8,
            description: "Wearing a blue dress with white shoes",
            lastSeenLocation: "Section B, Row 12",
            lastSeenTime: Date().addingTimeInterval(-1800),
            contactName: "Carlos Garcia",
            contactPhone: "555-0123",
            reportedByName: "Jane Doe",
            resolved: false,
            resolvedAt: nil,
            resolvedByName: nil,
            resolutionNotes: nil,
            createdAt: Date()
        )
    )
}
