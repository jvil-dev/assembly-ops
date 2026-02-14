//
//  CreateSessionSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/14/26.
//

// MARK: - Create Session Sheet
//
// Modal sheet for creating new event sessions (time blocks).
// Sessions represent specific time periods during which volunteers serve.
//
// Features:
//   - Event type-specific session templates (RC, CA, Special)
//   - Session name input field
//   - Date picker for session date
//   - Start and end time pickers (scroll wheels)
//   - Form validation (name and times required)
//   - Creates session in current event context
//   - Success/error handling with alerts
//
// Navigation:
//   - Presented as sheet from event management screens
//   - Dismisses after successful creation

import SwiftUI

// Template data structure
struct SessionTemplate: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let startHr: Int
    let startMin: Int
    let endHr: Int
    let endMin: Int
    let eventType: EventTemplateType
}

enum EventTemplateType {
    case circuitAssembly
    case regionalConvention
    case specialConvention
}

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
                    templateCard
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

    // MARK: - Template Card

    private var templateCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            sectionHeader(icon: "list.bullet.rectangle", title: "SESSION TEMPLATES")

            VStack(spacing: AppTheme.Spacing.s) {
                // Show templates filtered by event type
                ForEach(filteredTemplates) { template in
                    templateButton(
                        title: template.title,
                        subtitle: template.subtitle,
                        startHr: template.startHr,
                        startMin: template.startMin,
                        endHr: template.endHr,
                        endMin: template.endMin
                    )
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // Filter templates based on current event type
    private var filteredTemplates: [SessionTemplate] {
        guard let eventType = sessionState.selectedEvent?.eventType else {
            return allTemplates // Show all if no event selected (shouldn't happen)
        }

        switch eventType {
        case "CIRCUIT_ASSEMBLY":
            return allTemplates.filter { $0.eventType == .circuitAssembly }
        case "REGIONAL_CONVENTION":
            return allTemplates.filter { $0.eventType == .regionalConvention }
        case "SPECIAL_CONVENTION":
            return allTemplates.filter { $0.eventType == .specialConvention }
        default:
            return allTemplates
        }
    }

    // All available templates
    private var allTemplates: [SessionTemplate] {
        [
            // Regional Convention templates (3-day event, Friday-Sunday)
            SessionTemplate(
                title: "Regional Convention - Morning",
                subtitle: "9:20 AM - 12:10 PM",
                startHr: 9, startMin: 20,
                endHr: 12, endMin: 10,
                eventType: .regionalConvention
            ),
            SessionTemplate(
                title: "Regional Convention - Afternoon",
                subtitle: "1:40 PM - 4:40 PM",
                startHr: 13, startMin: 40,
                endHr: 16, endMin: 40,
                eventType: .regionalConvention
            ),
            // Circuit Assembly templates (1-day event)
            SessionTemplate(
                title: "Circuit Assembly - Morning",
                subtitle: "9:20 AM - 12:00 PM",
                startHr: 9, startMin: 20,
                endHr: 12, endMin: 0,
                eventType: .circuitAssembly
            ),
            SessionTemplate(
                title: "Circuit Assembly - Afternoon",
                subtitle: "1:30 PM - 4:00 PM",
                startHr: 13, startMin: 30,
                endHr: 16, endMin: 0,
                eventType: .circuitAssembly
            ),
            // Special Convention templates (same as Regional)
            SessionTemplate(
                title: "Special Convention - Morning",
                subtitle: "9:20 AM - 12:10 PM",
                startHr: 9, startMin: 20,
                endHr: 12, endMin: 10,
                eventType: .specialConvention
            ),
            SessionTemplate(
                title: "Special Convention - Afternoon",
                subtitle: "1:40 PM - 4:40 PM",
                startHr: 13, startMin: 40,
                endHr: 16, endMin: 40,
                eventType: .specialConvention
            )
        ]
    }

    private func templateButton(title: String, subtitle: String, startHr: Int, startMin: Int, endHr: Int, endMin: Int) -> some View {
        Button {
            HapticManager.shared.lightTap()
            startHour = startHr
            startMinute = startMin
            endHour = endHr
            endMinute = endMin

            // Auto-fill name if empty
            if viewModel.name.isEmpty {
                viewModel.name = title
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    Text(subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
            .padding(AppTheme.Spacing.m)
            .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            sectionHeader(icon: "calendar", title: "SESSION DETAILS")

            VStack(spacing: AppTheme.Spacing.m) {
                themedTextField("session.name".localized, text: $viewModel.name)

                DatePicker(
                    "session.date".localized,
                    selection: $viewModel.selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Time Card

    private var timeCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            sectionHeader(icon: "clock", title: "TIME RANGE")

            HStack(spacing: AppTheme.Spacing.l) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("session.startTime".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                    HStack(spacing: 4) {
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

                VStack(alignment: .leading, spacing: 8) {
                    Text("session.endTime".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                    HStack(spacing: 4) {
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

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.themeColor)
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
        }
    }

    private func themedTextField(
        _ placeholder: String,
        text: Binding<String>
    ) -> some View {
        TextField(placeholder, text: text)
            .padding(AppTheme.Spacing.m)
            .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
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
