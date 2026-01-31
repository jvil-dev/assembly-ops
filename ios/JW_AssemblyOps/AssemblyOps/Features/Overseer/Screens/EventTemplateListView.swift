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
    @State private var showJoinCodeAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                if viewModel.isLoadingTemplates {
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
        .navigationTitle("Activate Event")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadTemplates()
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
        .alert("Event Activated", isPresented: $showJoinCodeAlert) {
            Button("Go to Dashboard") {
                viewModel.completeSetup()
            }
        } message: {
            if let event = viewModel.activatedEvent {
                Text("Your event \"\(event.name)\" has been created.\n\nJoin Code: \(event.joinCode)\n\nShare this code with Department Overseers so they can join.")
            }
        }
        .onChange(of: viewModel.activatedEvent != nil) { activated in
            if activated {
                showJoinCodeAlert = true
            }
        }
    }

    // MARK: - Template Section

    private func templateSection(title: String, icon: String, templates: [EventTemplateItem], delay: Double) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
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
                    VStack(alignment: .leading, spacing: 4) {
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
}
