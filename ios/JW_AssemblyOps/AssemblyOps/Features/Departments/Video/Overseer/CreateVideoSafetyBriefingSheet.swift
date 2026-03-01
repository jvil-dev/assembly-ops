//
//  CreateVideoSafetyBriefingSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Create Video Safety Briefing Sheet
//
// Form for creating a new safety briefing for the video crew.
// Fields: topic, notes, attendee IDs (newline-separated).

import SwiftUI

struct CreateVideoSafetyBriefingSheet: View {
    @ObservedObject var viewModel: VideoSafetyViewModel
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var topic = ""
    @State private var notes = ""
    @State private var attendeeIdsText = ""
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Briefing Details card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .foregroundStyle(AppTheme.themeColor)
                            Text("BRIEFING DETAILS")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("av.briefing.topic".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            TextField("av.briefing.topicPlaceholder".localized, text: $topic)
                                .textFieldStyle(.plain)
                                .padding(AppTheme.Spacing.m)
                                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("av.briefing.notes".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .padding(AppTheme.Spacing.s)
                                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                        }
                    }
                    .cardPadding()
                    .themedCard(scheme: colorScheme)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Attendees card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.2")
                                .foregroundStyle(AppTheme.themeColor)
                            Text("ATTENDEES")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            Text("av.briefing.attendees".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            TextEditor(text: $attendeeIdsText)
                                .frame(minHeight: 80)
                                .padding(AppTheme.Spacing.s)
                                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                            Text("av.briefing.attendeesHint".localized)
                                .font(AppTheme.Typography.captionSmall)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
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
            .navigationTitle("av.briefing.create".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("av.briefing.save".localized) {
                        Task { await save() }
                    }
                    .disabled(topic.isEmpty || attendeeIdsText.isEmpty || viewModel.isSaving)
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
        let ids = attendeeIdsText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let success = await viewModel.createSafetyBriefing(
            eventId: eventId,
            topic: topic,
            notes: notes.isEmpty ? nil : notes,
            attendeeIds: ids
        )
        if success { dismiss() }
    }
}

#Preview {
    CreateVideoSafetyBriefingSheet(viewModel: VideoSafetyViewModel())
}

#Preview("Dark Mode") {
    CreateVideoSafetyBriefingSheet(viewModel: VideoSafetyViewModel())
        .preferredColorScheme(.dark)
}
