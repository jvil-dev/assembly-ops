//
//  EventSessionState.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Event Session State
//
// Singleton managing the current user's event session context.
// Tracks selected event and department for scoped data access.
// Used by both overseers and volunteers within EventTabView.
//
// Properties:
//   - selectedEvent: Currently active event for the session
//   - selectedDepartment: The overseer's purchased department
//   - events: List of events the overseer has access to
//   - departments: Department for this overseer (single dept)
//   - claimedDepartment: The department the overseer purchased
//
// Types:
//   - EventSummary: Lightweight event data for selection UI
//   - DepartmentSummary: Lightweight department data for selection UI
//
// Methods:
//   - loadEvents(): Fetch events via MyEventsQuery, auto-select first event
//   - loadForEvent(_:): Set up from EventMembershipItem (Events Hub entry)
//

import Foundation
import Combine
import Apollo

@MainActor
final class EventSessionState: ObservableObject {
    static let shared = EventSessionState()

    @Published var selectedEvent: EventSummary?
    @Published var selectedDepartment: DepartmentSummary?
    @Published var events: [EventSummary] = []
    @Published var departments: [DepartmentSummary] = []
    @Published var isLoading = false
    @Published var error: String?

    /// The department the overseer purchased
    @Published var claimedDepartment: DepartmentSummary?

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private init() {}

    // MARK: - Load Events

    func loadEvents() async {
        isLoading = true
        error = nil

        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.MyEventsQuery(),
                cachePolicy: .fetchIgnoringCacheData
            )

            guard let data = result.data?.myEvents else {
                error = "Failed to load events"
                isLoading = false
                return
            }

            var mappedEvents: [EventSummary] = []

            for eventAdmin in data {
                let event = eventAdmin.event

                let summary = EventSummary(
                    id: event.id,
                    name: event.name,
                    eventType: event.eventType.rawValue,
                    theme: nil,
                    venue: event.venue,
                    startDate: parseDate(event.startDate) ?? Date(),
                    endDate: parseDate(event.endDate) ?? Date(),
                    role: eventAdmin.role.rawValue,
                    volunteerCount: event.volunteerCount
                )
                mappedEvents.append(summary)

                // Store claimed department
                if let dept = eventAdmin.department {
                    claimedDepartment = DepartmentSummary(
                        id: dept.id,
                        name: dept.name,
                        departmentType: dept.departmentType.rawValue,
                        volunteerCount: dept.volunteerCount
                    )
                }
            }

            events = mappedEvents

            #if DEBUG
            print("[SessionState] loadEvents: \(events.count) events, claimedDepartment=\(claimedDepartment?.name ?? "nil")")
            #endif

            // Auto-select first event
            if let first = events.first {
                selectedEvent = first
                loadDepartment()
            }

        } catch {
            self.error = "Network error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Load Department

    /// Sets the overseer's single claimed department as the active selection.
    func loadDepartment() {
        if let claimed = claimedDepartment {
            departments = [claimed]
            selectedDepartment = claimed
        }
    }

    // MARK: - Load For Event (Events Hub entry point)

    /// Sets up session context from an EventMembershipItem (from Events Hub).
    /// Avoids a redundant MyEventsQuery by using data already fetched.
    func loadForEvent(_ membership: EventMembershipItem) {
        // Reset state
        selectedEvent = nil
        selectedDepartment = nil
        departments = []
        claimedDepartment = nil
        error = nil

        // Build EventSummary from membership data
        let summary = EventSummary(
            id: membership.eventId,
            name: membership.eventName,
            eventType: membership.eventType,
            theme: membership.theme,
            venue: membership.venue,
            startDate: membership.startDate,
            endDate: membership.endDate,
            role: membership.overseerRole ?? "DEPARTMENT_OVERSEER",
            volunteerCount: membership.volunteerCount
        )
        selectedEvent = summary

        // Set claimed department if present
        if let deptId = membership.departmentId,
           let deptName = membership.departmentName,
           let deptType = membership.departmentType {
            let dept = DepartmentSummary(
                id: deptId,
                name: deptName,
                departmentType: deptType,
                volunteerCount: 0,
                accessCode: membership.departmentAccessCode
            )
            claimedDepartment = dept
        }

        loadDepartment()

        #if DEBUG
        print("[SessionState] loadForEvent: \(summary.name), claimedDepartment=\(claimedDepartment?.name ?? "nil")")
        #endif
    }

    // MARK: - Helpers

    private func parseDate(_ dateString: String) -> Date? {
        // Try with fractional seconds first
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
        // Try without fractional seconds
        let fallbackFormatter = ISO8601DateFormatter()
        return fallbackFormatter.date(from: dateString)
    }
}

struct EventSummary: Identifiable, Hashable {
    let id: String
    let name: String
    let eventType: String
    let theme: String?
    let venue: String
    let startDate: Date
    let endDate: Date
    let role: String
    let volunteerCount: Int
}

struct DepartmentSummary: Identifiable, Hashable {
    let id: String
    let name: String
    let departmentType: String
    let volunteerCount: Int
    let accessCode: String?

    init(id: String, name: String, departmentType: String, volunteerCount: Int, accessCode: String? = nil) {
        self.id = id
        self.name = name
        self.departmentType = departmentType
        self.volunteerCount = volunteerCount
        self.accessCode = accessCode
    }
}
