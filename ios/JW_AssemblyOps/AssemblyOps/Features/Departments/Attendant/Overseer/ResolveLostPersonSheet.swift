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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Alert details (read-only)
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
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

                        Text(alert.description)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                        if let location = alert.lastSeenLocation {
                            Label(location, systemImage: "mappin")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

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

                        Text(String(format: "attendant.volunteer.reportedBy".localized, alert.reportedByName))
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                    .cardPadding()
                    .themedCard(scheme: colorScheme)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Resolution notes (required)
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                        SectionHeaderLabel(icon: "note.text", title: "attendant.lostPerson.resolutionNotes".localized)

                        TextEditor(text: $resolutionNotes)
                            .frame(minHeight: 100)
                            .padding(AppTheme.Spacing.s)
                            .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    }
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("attendant.lostPerson.resolve".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("attendant.lostPerson.resolve".localized) {
                        Task {
                            if let eventId = sessionState.selectedEvent?.id {
                                await viewModel.resolveAlert(id: alert.id, notes: resolutionNotes, eventId: eventId)
                                didResolve = true
                            }
                        }
                    }
                    .disabled(resolutionNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
