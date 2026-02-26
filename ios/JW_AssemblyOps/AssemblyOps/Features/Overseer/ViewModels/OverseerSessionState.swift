//
//  OverseerSessionState.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Overseer Session State
//
// Singleton managing the current overseer's session context.
// Tracks selected event, department, and user role for scoped data access.
//
// Properties:
//   - selectedEvent: Currently active event for the session
//   - selectedDepartment: Active department (nil for Event Overseers viewing all)
//   - events: List of events the overseer has access to
//   - departments: Departments within the selected event
//   - isEventOverseer: True if user has event-level access (can switch departments)
//   - claimedDepartment: The department a Department Overseer is assigned to
//
// Types:
//   - EventSummary: Lightweight event data for selection UI
//   - DepartmentSummary: Lightweight department data for selection UI
//
// Methods:
//   - loadEvents(): Fetch events via MyEventsQuery, auto-select first event
//   - loadDepartments(for:): Fetch departments for event (Event Overseers only)
//   - selectDepartment(_:): Change active department (Event Overseers only)
//
// Access Control:
//   - Event Overseers: Can view all departments, switch freely
//   - Department Overseers: Locked to their claimed department
//

import Foundation
import Combine
import Apollo

@MainActor
final class OverseerSessionState: ObservableObject {
    static let shared = OverseerSessionState()

    @Published var selectedEvent: EventSummary?
    @Published var selectedDepartment: DepartmentSummary?
    @Published var events: [EventSummary] = []
    @Published var departments: [DepartmentSummary] = []
    @Published var isLoading = false
    @Published var error: String?

    /// True if current user is an Event Overseer (can switch departments)
    @Published var isEventOverseer = false

    /// The department the overseer claimed (for Department Overseers)
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
            var foundEventOverseerRole = false

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

                // Check if this user is an App Admin for any event
                if eventAdmin.role == .case(.appAdmin) {
                    foundEventOverseerRole = true
                }

                // Store claimed department for any role that has one
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
            isEventOverseer = foundEventOverseerRole

            print("[SessionState] loadEvents: \(events.count) events, isEventOverseer=\(isEventOverseer), claimedDepartment=\(claimedDepartment?.name ?? "nil")")

            // Auto-select first event
            if let first = events.first {
                selectedEvent = first
                await loadDepartments(for: first.id)
            }

        } catch {
            self.error = "Network error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Load Departments

    @Published var isLoadingDepartments = false

    func loadDepartments(for eventId: String) async {
        // Department overseers can only see their claimed department
        guard isEventOverseer else {
            if let claimed = claimedDepartment {
                departments = [claimed]
                selectedDepartment = claimed
            }
            return
        }

        isLoadingDepartments = true

        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.EventDepartmentsQuery(eventId: eventId),
                cachePolicy: .fetchIgnoringCacheData
            )

            if let errors = result.errors, !errors.isEmpty {
                print("[SessionState] EventDepartmentsQuery errors: \(errors.map { $0.localizedDescription })")
            }

            guard let data = result.data?.eventDepartments else {
                print("[SessionState] EventDepartmentsQuery returned nil for eventId: \(eventId)")
                isLoadingDepartments = false
                return
            }

            print("[SessionState] EventDepartmentsQuery returned \(data.count) departments")

            departments = data.map { dept in
                DepartmentSummary(
                    id: dept.id,
                    name: dept.name,
                    departmentType: dept.departmentType.rawValue,
                    volunteerCount: dept.volunteerCount
                )
            }

            // Auto-select claimed department if available, otherwise view all
            if let claimed = claimedDepartment,
               departments.contains(where: { $0.id == claimed.id }) {
                selectedDepartment = claimed
            } else {
                selectedDepartment = nil
            }

        } catch {
            print("[SessionState] Failed to load departments: \(error)")
        }

        isLoadingDepartments = false
    }

    // MARK: - Load For Event (Events Hub entry point)

    /// Sets up session context from an EventMembershipItem (from Events Hub).
    /// Avoids a redundant MyEventsQuery by using data already fetched.
    func loadForEvent(_ membership: EventMembershipItem) async {
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
            theme: nil,
            venue: membership.venue,
            startDate: membership.startDate,
            endDate: membership.endDate,
            role: membership.overseerRole ?? "DEPARTMENT_OVERSEER",
            volunteerCount: membership.volunteerCount
        )
        selectedEvent = summary
        isEventOverseer = membership.overseerRole == "APP_ADMIN"

        // Set claimed department if present
        if let deptId = membership.departmentId,
           let deptName = membership.departmentName,
           let deptType = membership.departmentType {
            let dept = DepartmentSummary(
                id: deptId,
                name: deptName,
                departmentType: deptType,
                volunteerCount: 0 // Updated lazily when dashboard loads
            )
            claimedDepartment = dept
            selectedDepartment = dept
        }

        // For event overseers, load full department list
        if isEventOverseer {
            await loadDepartments(for: membership.eventId)
        } else if let claimed = claimedDepartment {
            departments = [claimed]
        }

        print("[SessionState] loadForEvent: \(summary.name), isEventOverseer=\(isEventOverseer), claimedDepartment=\(claimedDepartment?.name ?? "nil")")
    }

    // MARK: - Select Department

    func selectDepartment(_ department: DepartmentSummary?) {
        guard isEventOverseer else { return }
        selectedDepartment = department
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
}
