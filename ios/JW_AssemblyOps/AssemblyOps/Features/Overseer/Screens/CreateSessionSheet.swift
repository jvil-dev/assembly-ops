//
//  CreateSessionSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/14/26.
//

// MARK: - Create Session Sheet
//
// Modal sheet for creating additional custom sessions beyond the auto-created ones.
// Default Morning/Afternoon sessions are auto-created when an event is activated.
// This sheet is for custom sessions like "Lunch Break Coverage" or "Move-In Day".
//
// Features:
//   - Session name input field
//   - Date picker for session date
//   - Start and end time pickers (scroll wheels)
//   - Form validation (name and times required)
//   - Creates session in current event context

import SwiftUI

struct CreateSessionSheet: View {
    @StateObject private var viewModel = SessionsViewModel()
    @ObservedObject private var sessionState = OverseerSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false

    // Time picker state
    @State private var startHour: Int = 9
    @State private var startMinute: Int = 0
    @State private var endHour: Int = 12
    @State private var endMinute: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    infoCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    detailsCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    timeCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("session.create".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) {
                        Task {
                            guard let eventId = sessionState.selectedEvent?.id else { return }
                            await viewModel.createSession(eventId: eventId)
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isSaving)
                }
            }
            .alert("session.created".localized, isPresented: $viewModel.didCreate) {
                Button("common.ok".localized) { dismiss() }
            } message: {
                Text("session.createdMessage".localized(with: viewModel.name))
            }
            .alert("common.error".localized, isPresented: .constant(viewModel.error != nil)) {
                Button("common.ok".localized) { viewModel.error = nil }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
            .onChange(of: startHour) { _, _ in updateTimes() }
            .onChange(of: startMinute) { _, _ in updateTimes() }
            .onChange(of: endHour) { _, _ in updateTimes() }
            .onChange(of: endMinute) { _, _ in updateTimes() }
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.themeColor)

            Text("Morning and Afternoon sessions are created automatically. Use this to create additional custom sessions.")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "calendar", title: "SESSION DETAILS")

            VStack(spacing: AppTheme.Spacing.m) {
                themedTextField("session.name".localized, text: $viewModel.name)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("session.date".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    DatePicker(
                        "",
                        selection: $viewModel.selectedDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Time Card

    private var timeCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "clock", title: "TIME RANGE")

            HStack(spacing: AppTheme.Spacing.l) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                    Text("session.startTime".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                    HStack(spacing: AppTheme.Spacing.xs) {
                        Picker("Hour", selection: $startHour) {
                            ForEach(0..<24) { hour in
                                Text(String(format: "%02d", hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60)
                        .clipped()

                        Text(":")
                            .font(AppTheme.Typography.title)

                        Picker("Minute", selection: $startMinute) {
                            ForEach([0, 10, 20, 30, 40, 50], id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60)
                        .clipped()
                    }
                    .frame(height: 100)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                    Text("session.endTime".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                    HStack(spacing: AppTheme.Spacing.xs) {
                        Picker("Hour", selection: $endHour) {
                            ForEach(0..<24) { hour in
                                Text(String(format: "%02d", hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60)
                        .clipped()

                        Text(":")
                            .font(AppTheme.Typography.title)

                        Picker("Minute", selection: $endMinute) {
                            ForEach([0, 10, 20, 30, 40, 50], id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60)
                        .clipped()
                    }
                    .frame(height: 100)
                }
            }

            // Preview of selected time
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("\(formattedTime(startHour, startMinute)) - \(formattedTime(endHour, endMinute))")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
            }
            .padding(.top, AppTheme.Spacing.s)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Helpers

    private func themedTextField(
        _ label: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            TextField("", text: text)
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
    }

    private func updateTimes() {
        viewModel.startTime = String(format: "%02d:%02d", startHour, startMinute)
        viewModel.endTime = String(format: "%02d:%02d", endHour, endMinute)
    }

    private func formattedTime(_ hour: Int, _ minute: Int) -> String {
        let period = hour < 12 ? "AM" : "PM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }
}

#Preview {
    CreateSessionSheet()
}
