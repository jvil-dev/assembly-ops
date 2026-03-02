//
//  EventsHomeViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/25/26.
//

// MARK: - Events Home View Model
//
// Loads all events for the current user (both overseer and volunteer roles)
// via the myAllEvents query. Groups events by temporal status.
//
// Published:
//   - sections: grouped event memberships (Active, Upcoming, Past)
//   - isLoading, errorMessage
//
// Methods:
//   - load(): Fetch via MyAllEventsQuery
//   - refresh(): Pull-to-refresh

import Foundation
import Apollo
import Combine

// MARK: - Models

struct EventMembershipItem: Identifiable, Hashable {
    let id: String          // eventId
    let eventId: String
    let eventName: String
    let eventType: String   // raw enum value e.g. "CIRCUIT_ASSEMBLY_CO"
    let theme: String?      // convention theme e.g. "Declare the Good News!"
    let venue: String
    let address: String
    let startDate: Date
    let endDate: Date
    let volunteerCount: Int
    let membershipType: MembershipType
    // Overseer-specific
    let overseerRole: String?     // "DEPARTMENT_OVERSEER"
    let departmentId: String?
    let departmentName: String?
    let departmentType: String?
    let departmentAccessCode: String?
    // Volunteer-specific
    let eventVolunteerId: String?
    let volunteerId: String?
    // Hierarchy role (e.g. ASSISTANT_OVERSEER for volunteers with elevated access)
    let hierarchyRole: String?

    enum MembershipType: String, Hashable {
        case overseer
        case volunteer
    }

    var dateStatus: DateStatus {
        let now = Date()
        let cal = DateUtils.utcCalendar
        let startOfStartDay = cal.startOfDay(for: startDate)
        let endOfEndDay = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: endDate)) ?? endDate
        if startOfStartDay <= now && now < endOfEndDay { return .active }
        if startOfStartDay > now { return .future }
        return .past
    }

    enum DateStatus: String, Hashable {
        case active, future, past
    }

    var displayRole: String {
        switch membershipType {
        case .overseer:
            if let dept = departmentName {
                return String(format: "eventsHub.role.deptOverseer".localized, dept)
            }
            return "eventsHub.role.overseer".localized
        case .volunteer:
            if hierarchyRole == "ASSISTANT_OVERSEER", let dept = departmentName {
                return String(format: "eventsHub.role.asstOverseer".localized, dept)
            }
            return "eventsHub.role.volunteer".localized
        }
    }

    /// Events archive 30 days after they end
    var isArchived: Bool {
        guard dateStatus == .past else { return false }
        let archiveDate = DateUtils.utcCalendar.date(byAdding: .day, value: 30, to: endDate)
        return Date() > (archiveDate ?? endDate)
    }

    var displayEventType: String {
        switch eventType {
        case "CIRCUIT_ASSEMBLY_CO": return "Circuit Assembly with Circuit Overseer"
        case "CIRCUIT_ASSEMBLY_BR": return "Circuit Assembly with Branch Representative"
        case "REGIONAL_CONVENTION": return "Regional Convention"
        case "SPECIAL_CONVENTION": return "Special Convention"
        default: return eventType
        }
    }

    /// Theme + event type badge text (e.g. "Declare the Good News! — Circuit Assembly with Circuit Overseer")
    var themeBadgeText: String {
        if let theme, !theme.isEmpty {
            return "\(theme) — \(displayEventType)"
        }
        return displayEventType
    }

    var dateRangeString: String {
        DateUtils.formatEventDateRange(from: startDate, to: endDate)
    }
}

struct EventSection: Identifiable {
    let id: String
    let title: String
    let items: [EventMembershipItem]
}

// MARK: - ViewModel

@MainActor
final class EventsHomeViewModel: ObservableObject {
    @Published var sections: [EventSection] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() {
        isLoading = true
        errorMessage = nil

        NetworkClient.shared.apollo.fetch(
            query: AssemblyOpsAPI.MyAllEventsQuery(),
            cachePolicy: .fetchIgnoringCacheData
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.myAllEvents {
                        self?.processItems(data)
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
                self?.isLoading = false
            }
        }
    }

    func refresh() {
        load()
    }

    var isEmpty: Bool {
        sections.allSatisfy { $0.items.isEmpty } && !isLoading
    }

    // MARK: - Private

    private func processItems(_ raw: [AssemblyOpsAPI.MyAllEventsQuery.Data.MyAllEvent]) {
        let items: [EventMembershipItem] = raw.compactMap { e -> EventMembershipItem? in
            guard
                let start = DateUtils.parseISO8601(e.event.startDate),
                let end = DateUtils.parseISO8601(e.event.endDate)
            else { return nil }

            let membership: EventMembershipItem.MembershipType
            if case .case(.overseer) = e.membershipType {
                membership = .overseer
            } else {
                membership = .volunteer
            }

            return EventMembershipItem(
                id: e.eventId,
                eventId: e.eventId,
                eventName: e.event.name,
                eventType: e.event.eventType.rawValue,
                theme: e.event.theme,
                venue: e.event.venue,
                address: e.event.address,
                startDate: start,
                endDate: end,
                volunteerCount: e.event.volunteerCount,
                membershipType: membership,
                overseerRole: e.overseerRole?.rawValue,
                departmentId: e.departmentId,
                departmentName: e.departmentName,
                departmentType: e.departmentType?.rawValue,
                departmentAccessCode: e.departmentAccessCode,
                eventVolunteerId: e.eventVolunteerId,
                volunteerId: nil,
                hierarchyRole: e.hierarchyRole?.rawValue
            )
        }

        // Group by date status (archived items excluded from Past — shown in Settings > Archive)
        let active = items.filter { $0.dateStatus == .active }
        let future = items.filter { $0.dateStatus == .future }
        let past = items.filter { $0.dateStatus == .past && !$0.isArchived }

        var result: [EventSection] = []
        if !active.isEmpty {
            result.append(EventSection(id: "active", title: "eventsHub.section.active".localized, items: active))
        }
        if !future.isEmpty {
            result.append(EventSection(id: "future", title: "eventsHub.section.upcoming".localized, items: future))
        }
        if !past.isEmpty {
            result.append(EventSection(id: "past", title: "eventsHub.section.past".localized, items: past))
        }
        sections = result
    }
}
