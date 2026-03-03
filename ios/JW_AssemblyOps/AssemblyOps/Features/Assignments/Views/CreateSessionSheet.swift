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
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false

    // Time picker state (12-hr format)
    @State private var startHour12: Int = 9
    @State private var startMinute: Int = 0
    @State private var startPeriod: TimePeriod = .am
    @State private var endHour12: Int = 12
    @State private var endMinute: Int = 0
    @State private var endPeriod: TimePeriod = .pm

    enum TimePeriod: String, CaseIterable {
        case am = "AM"
        case pm = "PM"
    }

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
            .onChange(of: startHour12) { _, _ in updateTimes() }
            .onChange(of: startMinute) { _, _ in updateTimes() }
            .onChange(of: startPeriod) { _, _ in updateTimes() }
            .onChange(of: endHour12) { _, _ in updateTimes() }
            .onChange(of: endMinute) { _, _ in updateTimes() }
            .onChange(of: endPeriod) { _, _ in updateTimes() }
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

            VStack(spacing: AppTheme.Spacing.l) {
                // Start time
                VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                    Text("session.startTime".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                    HStack(spacing: 4) {
                        Picker("Hour", selection: $startHour12) {
                            ForEach(1...12, id: \.self) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 50)
                        .clipped()

                        Text(":")
                            .font(AppTheme.Typography.title)

                        Picker("Minute", selection: $startMinute) {
                            ForEach([0, 10, 20, 30, 40, 50], id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 50)
                        .clipped()

                        Picker("Period", selection: $startPeriod) {
                            ForEach(TimePeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 55)
                        .clipped()
                    }
                    .frame(height: 100)
                }

                // End time
                VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                    Text("session.endTime".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                    HStack(spacing: 4) {
                        Picker("Hour", selection: $endHour12) {
                            ForEach(1...12, id: \.self) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 50)
                        .clipped()

                        Text(":")
                            .font(AppTheme.Typography.title)

                        Picker("Minute", selection: $endMinute) {
                            ForEach([0, 10, 20, 30, 40, 50], id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 50)
                        .clipped()

                        Picker("Period", selection: $endPeriod) {
                            ForEach(TimePeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 55)
                        .clipped()
                    }
                    .frame(height: 100)
                }
            }

            // Preview of selected time
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("\(formattedTime12(startHour12, startMinute, startPeriod)) - \(formattedTime12(endHour12, endMinute, endPeriod))")
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

    private func to24Hour(_ hour12: Int, _ period: TimePeriod) -> Int {
        if period == .am {
            return hour12 == 12 ? 0 : hour12
        } else {
            return hour12 == 12 ? 12 : hour12 + 12
        }
    }

    private func updateTimes() {
        let startH = to24Hour(startHour12, startPeriod)
        let endH = to24Hour(endHour12, endPeriod)
        viewModel.startTime = String(format: "%02d:%02d", startH, startMinute)
        viewModel.endTime = String(format: "%02d:%02d", endH, endMinute)
    }

    private func formattedTime12(_ hour12: Int, _ minute: Int, _ period: TimePeriod) -> String {
        return String(format: "%d:%02d %@", hour12, minute, period.rawValue)
    }
}

#Preview {
    CreateSessionSheet()
}
