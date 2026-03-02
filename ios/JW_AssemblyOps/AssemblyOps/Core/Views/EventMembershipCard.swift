//
//  EventMembershipCard.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/25/26.
//

// MARK: - Event Membership Card
//
// Reusable card for the Events Hub showing event info and user's role.
// Status indicator: green (active), blue (upcoming), gray (past).
// Displays event type pill, name, venue, dates, role badge, and chevron.

import SwiftUI

struct EventMembershipCard: View {
    let item: EventMembershipItem
    let colorScheme: ColorScheme

    private var accentColor: Color {
        if let deptType = item.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    private var statusColor: Color {
        switch item.dateStatus {
        case .active: return AppTheme.StatusColors.accepted
        case .future: return AppTheme.themeColor
        case .past: return AppTheme.textTertiary(for: colorScheme)
        }
    }

    private var statusLabel: String {
        switch item.dateStatus {
        case .active: return "eventsHub.status.active".localized
        case .future: return "eventsHub.section.upcoming".localized
        case .past: return "eventsHub.section.past".localized
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top strip — event type + status dot
            HStack {
                Text(item.displayEventType.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(colorScheme == .dark ? 0.25 : 0.1))
                    )
                    .foregroundStyle(accentColor)

                Spacer()

                // Status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(statusLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(statusColor)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.cardPadding)
            .padding(.top, AppTheme.Spacing.cardPadding)
            .padding(.bottom, AppTheme.Spacing.m)

            // Divider
            Rectangle()
                .fill(AppTheme.dividerColor(for: colorScheme))
                .frame(height: 1)
                .padding(.horizontal, AppTheme.Spacing.cardPadding)

            // Body
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                // Event name
                Text(item.eventName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.1))
                    .fixedSize(horizontal: false, vertical: true)

                // Meta rows
                VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                    metaRow(icon: "mappin.circle.fill", text: item.venue)
                    metaRow(icon: "calendar", text: item.dateRangeString)
                    metaRow(icon: "person.2.fill", text: "\(item.volunteerCount) volunteers")
                }
            }
            .padding(.horizontal, AppTheme.Spacing.cardPadding)
            .padding(.top, AppTheme.Spacing.m)
            .padding(.bottom, AppTheme.Spacing.m)

            // Divider
            Rectangle()
                .fill(AppTheme.dividerColor(for: colorScheme))
                .frame(height: 1)
                .padding(.horizontal, AppTheme.Spacing.cardPadding)

            // Footer — role badge + chevron
            HStack {
                // Role badge
                HStack(spacing: 6) {
                    Image(systemName: item.membershipType == .overseer ? "shield.fill" : "person.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(item.membershipType == .overseer ? accentColor : AppTheme.textTertiary(for: colorScheme))

                    Text(item.displayRole)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
            .padding(.horizontal, AppTheme.Spacing.cardPadding)
            .padding(.vertical, AppTheme.Spacing.m)
        }
        .themedCard(scheme: colorScheme)
    }

    private func metaRow(icon: String, text: String) -> some View {
        HStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(accentColor.opacity(0.7))
                .frame(width: 18)
            Text(text)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
    }
}

#Preview {
    EventMembershipCard(
        item: EventMembershipItem(
            id: "1",
            eventId: "1",
            eventName: "2026 Circuit Assembly",
            eventType: "CIRCUIT_ASSEMBLY_CO",
            theme: "Declare the Good News!",
            venue: "Assembly Hall of Jehovah's Witnesses",
            address: "123 Main St, Anytown, USA",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 2),
            volunteerCount: 45,
            membershipType: .overseer,
            overseerRole: "DEPARTMENT_OVERSEER",
            departmentId: "d1",
            departmentName: "Attendant",
            departmentType: "ATTENDANT",
            departmentAccessCode: "ABC123",
            eventVolunteerId: nil,
            volunteerId: nil,
            hierarchyRole: nil
        ),
        colorScheme: .light
    )
    .padding()
}
