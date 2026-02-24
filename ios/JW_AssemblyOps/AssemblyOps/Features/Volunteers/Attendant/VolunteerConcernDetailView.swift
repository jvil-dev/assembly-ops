//
//  VolunteerConcernDetailView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/21/26.
//

// MARK: - Volunteer Concern Detail View
//
// Read-only detail screen for a safety incident or lost person alert.
// Accessible to attendant volunteers from the concerns feed.
//
// - Incidents: type, description, location, reported by/at, resolution status
// - Lost person alerts: person info, last seen, contact, reported by/at,
//   live elapsed timer if unresolved (updates every minute)
//

import SwiftUI
import Combine

struct VolunteerConcernDetailView: View {
    let concern: ConcernItem

    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var now = Date()

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                switch concern {
                case .incident(let incident):
                    incidentDetail(incident)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                case .alert(let alert):
                    alertDetail(alert)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
        .onReceive(timer) { date in
            now = date
        }
    }

    // MARK: - Navigation Title

    private var navigationTitle: String {
        switch concern {
        case .incident(let i): return i.type.displayName
        case .alert(let a): return a.personName
        }
    }

    // MARK: - Incident Detail

    private func incidentDetail(_ incident: SafetyIncidentItem) -> some View {
        VStack(spacing: AppTheme.Spacing.l) {
            // Status + type header
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                HStack {
                    Image(systemName: incident.type.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(incident.resolved ? AppTheme.StatusColors.accepted : AppTheme.StatusColors.warning)
                    Text(incident.type.displayName)
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(.primary)
                    Spacer()
                    statusBadge(resolved: incident.resolved, activeColor: AppTheme.StatusColors.warning)
                }
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)

            // Description
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                sectionHeader(icon: "text.alignleft", label: "attendant.incidents.description".localized)
                Text(incident.description)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)

            // Location / Post
            if incident.location != nil || incident.postName != nil {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                    sectionHeader(icon: "mappin.and.ellipse", label: "attendant.incidents.location".localized)
                    if let location = incident.location {
                        detailRow(icon: "mappin", text: location)
                    }
                    if let postName = incident.postName {
                        detailRow(icon: "map", text: postName)
                    }
                }
                .cardPadding()
                .themedCard(scheme: colorScheme)
            }

            // Reported by / at
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                sectionHeader(icon: "person.circle", label: "attendant.concerns.reportedBy".localized)
                detailRow(icon: "person", text: incident.reportedByName)
                detailRow(icon: "clock", text: DateUtils.timeAgo(from: incident.createdAt))
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)

            // Resolution (if resolved)
            if incident.resolved {
                resolutionCard(
                    resolvedByName: incident.resolvedByName,
                    resolvedAt: incident.resolvedAt,
                    notes: incident.resolutionNotes
                )
            }
        }
    }

    // MARK: - Alert Detail

    private func alertDetail(_ alert: LostPersonAlertItem) -> some View {
        VStack(spacing: AppTheme.Spacing.l) {
            // Status + name header
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                HStack(alignment: .top) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 24))
                        .foregroundStyle(alert.resolved ? AppTheme.StatusColors.accepted : AppTheme.StatusColors.declined)
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(alert.personName)
                            .font(AppTheme.Typography.title)
                            .foregroundStyle(.primary)
                        if let age = alert.age {
                            Text("Age \(age)")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        }
                    }
                    Spacer()
                    statusBadge(resolved: alert.resolved, activeColor: AppTheme.StatusColors.declined)
                }

                // Elapsed timer: live while unresolved, frozen at resolvedAt once closed
                let elapsedEnd = alert.resolvedAt ?? now
                let elapsedColor = alert.resolved ? AppTheme.StatusColors.accepted : AppTheme.StatusColors.declined
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: alert.resolved ? "timer.circle.fill" : "timer")
                        .foregroundStyle(elapsedColor)
                    Text(DateUtils.elapsedString(from: alert.createdAt, to: elapsedEnd))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(elapsedColor)
                    Text(alert.resolved ? "attendant.concerns.totalTime".localized : "attendant.concerns.elapsed".localized)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
                .padding(.top, AppTheme.Spacing.s)
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)

            // Description
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                sectionHeader(icon: "text.alignleft", label: "attendant.incidents.description".localized)
                Text(alert.description)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)

            // Last seen
            if alert.lastSeenLocation != nil || alert.lastSeenTime != nil {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                    sectionHeader(icon: "mappin.and.ellipse", label: "attendant.lostPerson.lastSeen".localized)
                    if let location = alert.lastSeenLocation {
                        detailRow(icon: "mappin", text: location)
                    }
                    if let time = alert.lastSeenTime {
                        detailRow(icon: "clock", text: DateUtils.timeAgo(from: time))
                    }
                }
                .cardPadding()
                .themedCard(scheme: colorScheme)
            }

            // Contact
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                sectionHeader(icon: "phone.circle", label: "attendant.lostPerson.contact".localized)
                detailRow(icon: "person", text: alert.contactName)
                if let phone = alert.contactPhone {
                    HStack(spacing: AppTheme.Spacing.s) {
                        Image(systemName: "phone")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        Link(phone, destination: URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))")!)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.themeColor)
                        Spacer()
                    }
                }
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)

            // Reported by / at
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                sectionHeader(icon: "person.circle", label: "attendant.concerns.reportedBy".localized)
                detailRow(icon: "person", text: alert.reportedByName)
                detailRow(icon: "clock", text: DateUtils.timeAgo(from: alert.createdAt))
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)

            // Resolution (if resolved)
            if alert.resolved {
                resolutionCard(
                    resolvedByName: alert.resolvedByName,
                    resolvedAt: alert.resolvedAt,
                    notes: alert.resolutionNotes
                )
            }
        }
    }

    // MARK: - Shared Sub-Views

    private func sectionHeader(icon: String, label: String) -> some View {
        HStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.themeColor)
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
        }
    }

    private func detailRow(icon: String, text: String) -> some View {
        HStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            Spacer()
        }
    }

    private func statusBadge(resolved: Bool, activeColor: Color) -> some View {
        Group {
            if resolved {
                Text("attendant.incidents.resolved".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.StatusColors.accepted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.StatusColors.acceptedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
            } else {
                Text("attendant.concerns.status.active".localized)
                    .textCase(.uppercase)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(activeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(activeColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
            }
        }
    }

    private func resolutionCard(resolvedByName: String?, resolvedAt: Date?, notes: String?) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            sectionHeader(icon: "checkmark.shield.fill", label: "attendant.incidents.resolved".localized)

            if let name = resolvedByName {
                detailRow(icon: "person.badge.shield.checkmark", text: name)
            }
            if let date = resolvedAt {
                detailRow(icon: "clock.badge.checkmark", text: DateUtils.timeAgo(from: date))
            }
            if let notes = notes {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("attendant.incidents.notes".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text(notes)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
                .padding(AppTheme.Spacing.s)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }
}

#Preview {
    NavigationStack {
        VolunteerConcernDetailView(concern: .incident(SafetyIncidentItem(
            id: "1",
            type: .wetFloor,
            description: "Wet floor near entrance B",
            location: "Entrance B",
            postId: "post-3",
            postName: "Post 3",
            reportedByName: "John Doe",
            resolved: false,
            resolvedAt: nil,
            resolvedByName: nil,
            resolutionNotes: nil,
            createdAt: Date().addingTimeInterval(-900)
        )))
    }
}
