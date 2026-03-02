//
//  AudioSafetyBriefingsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - AV Safety Briefings View
//
// List of safety briefings with attendee count, create, and edit notes.

import SwiftUI

struct AudioSafetyBriefingsView: View {
    @StateObject private var viewModel = AudioSafetyViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showCreateBriefing = false
    @State private var showError = false

    private var accentColor: Color {
        if let deptType = sessionState.selectedDepartment?.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.safetyBriefings.isEmpty {
                    VStack(spacing: AppTheme.Spacing.m) {
                        Image(systemName: "person.3.sequence")
                            .font(.system(size: 40))
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        Text("av.briefing.empty".localized)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.xxl)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                } else {
                    ForEach(Array(viewModel.safetyBriefings.enumerated()), id: \.element.id) { index, briefing in
                        briefingCard(briefing)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.03)
                    }
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("av.briefing.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateBriefing = true
                    HapticManager.shared.lightTap()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateBriefing) {
            CreateSafetyBriefingSheet(viewModel: viewModel)
        }
        .onChange(of: viewModel.error) { _, error in
            showError = error != nil
        }
        .alert("common.error".localized, isPresented: $showError) {
            Button("common.ok".localized) { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .refreshable {
            if let eventId = sessionState.selectedEvent?.id {
                await viewModel.loadBriefings(eventId: eventId)
            }
        }
        .task {
            if let eventId = sessionState.selectedEvent?.id {
                await viewModel.loadBriefings(eventId: eventId)
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Briefing Card

    private func briefingCard(_ briefing: AudioSafetyBriefingItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack {
                Image(systemName: "person.3.sequence")
                    .foregroundStyle(accentColor)
                Text(briefing.topic)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Button(role: .destructive) {
                    Task {
                        _ = await viewModel.deleteSafetyBriefing(id: briefing.id)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
            }

            if let notes = briefing.notes, !notes.isEmpty {
                Text(notes)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .lineLimit(3)
            }

            HStack {
                Label("\(briefing.attendeeCount)", systemImage: "person.2")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                Spacer()
                Text(briefing.conductedByName)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                Text(briefing.conductedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Attendee list (expandable)
            if !briefing.attendees.isEmpty {
                DisclosureGroup("av.briefing.attendees".localized) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        ForEach(briefing.attendees) { attendee in
                            Text(attendee.volunteerName)
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.top, AppTheme.Spacing.s)
                }
                .font(AppTheme.Typography.caption)
                .foregroundStyle(accentColor)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }
}

#Preview {
    NavigationStack {
        AudioSafetyBriefingsView()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        AudioSafetyBriefingsView()
    }
    .preferredColorScheme(.dark)
}
