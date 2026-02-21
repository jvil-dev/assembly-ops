//
//  EventTemplateListView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/31/26.
//

// MARK: - Event Template List View
//
// Displays available event templates grouped by type.
// Allows Event Overseers to activate a template to create a new event.
//
// Sections:
//   - Circuit Assemblies
//   - Regional Conventions
//
// After activation, shows the join code for sharing.
//

import SwiftUI

struct EventTemplateListView: View {
    @ObservedObject var viewModel: EventSetupViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                if viewModel.activatedEvent != nil {
                    // Post-activation: show join code + department claiming
                    activatedContent
                } else if viewModel.isLoadingTemplates {
                    ProgressView("Loading templates...")
                        .padding(.top, AppTheme.Spacing.xxl)
                } else if viewModel.templates.isEmpty {
                    emptyState
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                } else {
                    // Circuit Assemblies
                    if !viewModel.circuitAssemblyTemplates.isEmpty {
                        templateSection(
                            title: "Circuit Assemblies",
                            icon: "building.columns.fill",
                            templates: viewModel.circuitAssemblyTemplates,
                            delay: 0
                        )
                    }

                    // Regional Conventions
                    if !viewModel.regionalConventionTemplates.isEmpty {
                        templateSection(
                            title: "Regional Conventions",
                            icon: "globe.americas.fill",
                            templates: viewModel.regionalConventionTemplates,
                            delay: 0.1
                        )
                    }
                }

                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle(viewModel.activatedEvent != nil ? "Event Activated" : "Activate Event")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadTemplates()
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Activated Content

    private var activatedContent: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Success header
            VStack(spacing: AppTheme.Spacing.m) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.StatusColors.accepted)

                Text("Event Created!")
                    .font(AppTheme.Typography.title)
                    .fontWeight(.bold)
            }
            .padding(.vertical, AppTheme.Spacing.l)

            // Event info + join code card
            if let event = viewModel.activatedEvent {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                    HStack(spacing: AppTheme.Spacing.s) {
                        Image(systemName: "calendar.circle.fill")
                            .foregroundStyle(AppTheme.themeColor)
                        Text("Event Details")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }

                    Text(event.name)
                        .font(AppTheme.Typography.headline)
                        .fontWeight(.semibold)

                    Label(event.venue, systemImage: "mappin")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text("Join Code")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            Text(event.joinCode)
                                .font(.system(.title2, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.themeColor)
                        }
                        Spacer()
                        Button {
                            UIPasteboard.general.string = event.joinCode
                            HapticManager.shared.lightTap()
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.title3)
                                .foregroundStyle(AppTheme.themeColor)
                        }
                    }

                    Text("Share this code with Department Overseers so they can join.")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
                .cardPadding()
                .themedCard(scheme: colorScheme)
            }

            // Department claiming section
            if !viewModel.availableDepartments.isEmpty || viewModel.isLoadingDepartments {
                departmentClaimSection
            }

            // Skip / Go to dashboard
            Button {
                viewModel.completeSetup()
            } label: {
                Text(viewModel.availableDepartments.isEmpty && !viewModel.isLoadingDepartments
                    ? "Go to Dashboard"
                    : "Skip for Now")
                    .font(AppTheme.Typography.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.l)
                    .background(viewModel.availableDepartments.isEmpty && !viewModel.isLoadingDepartments
                        ? AppTheme.themeColor
                        : AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .foregroundStyle(viewModel.availableDepartments.isEmpty && !viewModel.isLoadingDepartments
                        ? .white
                        : AppTheme.textSecondary(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
            }
        }
    }

    // MARK: - Department Claim Section

    private var departmentClaimSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("Claim Your Department")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text("Select the department you'll be overseeing:")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            if viewModel.isLoadingDepartments {
                ProgressView()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.m) {
                    ForEach(viewModel.availableDepartments, id: \.self) { deptType in
                        departmentButton(deptType)
                    }
                }
            }

            // Error
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.red)
            }

            // Claim button
            if let selected = viewModel.selectedDepartmentType,
               let event = viewModel.activatedEvent {
                Button {
                    viewModel.claimDepartment(eventId: event.id, departmentType: selected)
                } label: {
                    HStack(spacing: AppTheme.Spacing.s) {
                        if viewModel.isClaiming {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Claim \(formatDepartment(selected))")
                                .font(AppTheme.Typography.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.l)
                    .background(AppTheme.themeColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                }
                .disabled(viewModel.isClaiming)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Department Button

    private func departmentButton(_ deptType: String) -> some View {
        Button {
            viewModel.selectedDepartmentType = deptType
            HapticManager.shared.lightTap()
        } label: {
            VStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: departmentIcon(deptType))
                    .font(.title3)
                    .foregroundStyle(viewModel.selectedDepartmentType == deptType
                        ? AppTheme.themeColor
                        : AppTheme.textSecondary(for: colorScheme))

                Text(formatDepartment(deptType))
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(viewModel.selectedDepartmentType == deptType
                        ? (colorScheme == .dark ? .white : .primary)
                        : AppTheme.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.m)
            .background(viewModel.selectedDepartmentType == deptType
                ? AppTheme.themeColor.opacity(0.1)
                : AppTheme.cardBackgroundSecondary(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(viewModel.selectedDepartmentType == deptType
                        ? AppTheme.themeColor
                        : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Template Section

    private func templateSection(title: String, icon: String, templates: [EventTemplateItem], delay: Double) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.themeColor)
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, AppTheme.Spacing.xs)

            ForEach(Array(templates.enumerated()), id: \.element.id) { index, template in
                templateCard(template)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: delay + Double(index) * 0.03)
            }
        }
    }

    // MARK: - Template Card

    private func templateCard(_ template: EventTemplateItem) -> some View {
        Button {
            guard !template.isActivated else { return }
            viewModel.activateEvent(templateId: template.id)
            HapticManager.shared.lightTap()
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(template.name)
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(template.isActivated
                                ? AppTheme.textTertiary(for: colorScheme)
                                : (colorScheme == .dark ? .white : .primary))

                        if let theme = template.theme {
                            Text(theme)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.themeColor)
                        }
                    }
                    Spacer()

                    if template.isActivated {
                        Text("Activated")
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(AppTheme.StatusColors.accepted)
                            .padding(.horizontal, AppTheme.Spacing.s)
                            .padding(.vertical, 4)
                            .background(AppTheme.StatusColors.acceptedBackground)
                            .clipShape(Capsule())
                    } else if viewModel.isActivating {
                        ProgressView()
                    }

                    Text(template.language.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .clipShape(Capsule())
                }

                HStack(spacing: AppTheme.Spacing.l) {
                    Label(template.venue, systemImage: "mappin")
                    Spacer()
                    if let circuit = template.circuit {
                        Label(circuit, systemImage: "circle.grid.2x2")
                    }
                }
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                HStack(spacing: AppTheme.Spacing.l) {
                    Label(formatDate(template.startDate), systemImage: "calendar")
                    Spacer()
                    Label(template.region, systemImage: "location")
                }
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
            .opacity(template.isActivated ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(template.isActivated || viewModel.isActivating)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Text("No Templates Available")
                .font(AppTheme.Typography.headline)

            Text("No event templates are available yet. Contact the branch office or check back later.")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppTheme.Spacing.xxl)
    }

    // MARK: - Helpers

    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: isoString) {
            let display = DateFormatter()
            display.dateStyle = .medium
            return display.string(from: date)
        }
        // Try without fractional seconds
        let fallback = ISO8601DateFormatter()
        if let date = fallback.date(from: isoString) {
            let display = DateFormatter()
            display.dateStyle = .medium
            return display.string(from: date)
        }
        return isoString
    }

    private func formatDepartment(_ type: String) -> String {
        switch type {
        case "ACCOUNTS": return "Accounts"
        case "ATTENDANT": return "Attendant"
        case "AUDIO_VIDEO": return "Audio/Video"
        case "BAPTISM": return "Baptism"
        case "CLEANING": return "Cleaning"
        case "FIRST_AID": return "First Aid"
        case "INFORMATION_VOLUNTEER_SERVICE": return "Information"
        case "INSTALLATION": return "Installation"
        case "LOST_FOUND_CHECKROOM": return "Lost & Found"
        case "PARKING": return "Parking"
        case "ROOMING": return "Rooming"
        case "TRUCKING_EQUIPMENT": return "Trucking"
        default: return type
        }
    }

    private func departmentIcon(_ type: String) -> String {
        switch type {
        case "ACCOUNTS": return "dollarsign.circle"
        case "ATTENDANT": return "person.2"
        case "AUDIO_VIDEO": return "speaker.wave.2"
        case "BAPTISM": return "drop"
        case "CLEANING": return "sparkles"
        case "FIRST_AID": return "cross.case"
        case "INFORMATION_VOLUNTEER_SERVICE": return "info.circle"
        case "INSTALLATION": return "hammer"
        case "LOST_FOUND_CHECKROOM": return "questionmark.folder"
        case "PARKING": return "car"
        case "ROOMING": return "bed.double"
        case "TRUCKING_EQUIPMENT": return "truck.box"
        default: return "square.grid.2x2"
        }
    }
}

// MARK: - Previews

#Preview("Templates") {
    NavigationStack {
        EventTemplateListView(viewModel: {
            let vm = EventSetupViewModel()
            vm.templates = [
                EventTemplateItem(id: "1", eventType: "CIRCUIT_ASSEMBLY", circuit: "CA-7", region: "US-South", serviceYear: 2026, name: "Circuit Assembly with CO Visit", theme: "Keep Walking by Spirit", themeScripture: "Galatians 5:16", venue: "Assembly Hall of Jehovah's Witnesses", address: "123 Assembly Dr", startDate: "2026-03-15T00:00:00Z", endDate: "2026-03-16T00:00:00Z", language: "EN", isActivated: false),
                EventTemplateItem(id: "2", eventType: "CIRCUIT_ASSEMBLY", circuit: "CA-7", region: "US-South", serviceYear: 2026, name: "Circuit Assembly", theme: nil, themeScripture: nil, venue: "Assembly Hall of Jehovah's Witnesses", address: "123 Assembly Dr", startDate: "2026-06-20T00:00:00Z", endDate: "2026-06-21T00:00:00Z", language: "ES", isActivated: true),
                EventTemplateItem(id: "3", eventType: "REGIONAL_CONVENTION", circuit: nil, region: "US-South", serviceYear: 2026, name: "Regional Convention 2026", theme: "Declare the Good News!", themeScripture: "Mark 13:10", venue: "NRG Center", address: "1 NRG Park", startDate: "2026-07-04T00:00:00Z", endDate: "2026-07-06T00:00:00Z", language: "EN", isActivated: false),
            ]
            return vm
        }())
    }
}

#Preview("Activated") {
    NavigationStack {
        EventTemplateListView(viewModel: {
            let vm = EventSetupViewModel()
            vm.activatedEvent = ActivatedEventInfo(
                id: "evt-1",
                name: "Circuit Assembly with CO Visit",
                joinCode: "ABC123",
                venue: "Assembly Hall of Jehovah's Witnesses"
            )
            vm.availableDepartments = ["ATTENDANT", "PARKING", "CLEANING", "FIRST_AID", "AUDIO_VIDEO", "ACCOUNTS"]
            return vm
        }())
    }
}

#Preview("Empty") {
    NavigationStack {
        EventTemplateListView(viewModel: EventSetupViewModel())
    }
}

#Preview("Dark") {
    NavigationStack {
        EventTemplateListView(viewModel: {
            let vm = EventSetupViewModel()
            vm.templates = [
                EventTemplateItem(id: "1", eventType: "CIRCUIT_ASSEMBLY", circuit: "CA-7", region: "US-South", serviceYear: 2026, name: "Circuit Assembly with CO Visit", theme: "Keep Walking by Spirit", themeScripture: nil, venue: "Assembly Hall", address: "123 Assembly Dr", startDate: "2026-03-15T00:00:00Z", endDate: "2026-03-16T00:00:00Z", language: "EN", isActivated: false),
            ]
            return vm
        }())
    }
    .preferredColorScheme(.dark)
}
