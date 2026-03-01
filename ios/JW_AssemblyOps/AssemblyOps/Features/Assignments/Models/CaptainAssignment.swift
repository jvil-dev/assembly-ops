//
//  CaptainAssignment.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/1/26.
//

// MARK: - Captain Assignment Model
//
// Local model representing a captain's area assignment.
// Parsed from GraphQL MyCaptainAssignmentsQuery response.
// Mirrors the Assignment model pattern for post assignments,
// but represents area captain roles instead.
//
// Used by: AssignmentsViewModel, CaptainAssignmentCardView, CaptainAssignmentDetailView

import Foundation

struct CaptainAssignment: Identifiable, Equatable, Hashable {
    let id: String
    let areaId: String
    let areaName: String
    let areaDescription: String?
    let areaCategory: String?
    let departmentId: String
    let departmentName: String
    let departmentType: String
    let eventId: String
    let sessionId: String
    let sessionName: String
    let date: Date
    let startTime: Date
    let endTime: Date
    var status: AssignmentStatus
    var respondedAt: Date?
    var declineReason: String?
    var acceptedDeadline: Date?
    var forceAssigned: Bool

    // MARK: - Computed Properties

    var canRespond: Bool {
        status == .pending && !forceAssigned
    }

    var isPending: Bool {
        status == .pending
    }

    var isAccepted: Bool {
        status == .accepted
    }

    var deadlineText: String? {
        guard let deadline = acceptedDeadline, status == .pending else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        if days <= 0 {
            return "Respond today"
        } else if days == 1 {
            return "1 day to respond"
        } else {
            return "\(days) days to respond"
        }
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var isUpcoming: Bool {
        date > Date()
    }

    var timeRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CaptainAssignment, rhs: CaptainAssignment) -> Bool {
        lhs.id == rhs.id &&
        lhs.status == rhs.status
    }
}

// MARK: - GraphQL Mapping

extension CaptainAssignment {
    init?(from graphQL: AssemblyOpsAPI.MyCaptainAssignmentsQuery.Data.MyCaptainAssignment) {
        self.id = graphQL.id
        self.areaId = graphQL.area.id
        self.areaName = graphQL.area.name
        self.areaDescription = graphQL.area.description
        self.areaCategory = graphQL.area.category
        self.departmentId = graphQL.area.department.id
        self.departmentName = graphQL.area.department.name
        self.departmentType = graphQL.area.department.departmentType.rawValue
        self.eventId = graphQL.area.department.event.id
        self.sessionId = graphQL.session.id
        self.sessionName = graphQL.session.name

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = isoFormatter.date(from: graphQL.session.date),
              let startTime = isoFormatter.date(from: graphQL.session.startTime),
              let endTime = isoFormatter.date(from: graphQL.session.endTime) else {
            return nil
        }

        self.date = date
        self.startTime = startTime
        self.endTime = endTime

        self.status = AssignmentStatus(rawValue: graphQL.status.rawValue) ?? .pending
        self.respondedAt = graphQL.respondedAt.flatMap { isoFormatter.date(from: $0) }
        self.declineReason = graphQL.declineReason
        self.acceptedDeadline = graphQL.acceptedDeadline.flatMap { isoFormatter.date(from: $0) }
        self.forceAssigned = graphQL.forceAssigned
    }
}

// MARK: - Preview Data

extension CaptainAssignment {
    static var preview: CaptainAssignment {
        CaptainAssignment(
            id: "cap-1",
            areaId: "area-1",
            areaName: "East Wing",
            areaDescription: "East side of the building",
            areaCategory: "Interior",
            departmentId: "dept-1",
            departmentName: "Attendant",
            departmentType: "ATTENDANT",
            eventId: "event-preview",
            sessionId: "session-1",
            sessionName: "Saturday Morning",
            date: Date(),
            startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!,
            status: .pending,
            respondedAt: nil,
            declineReason: nil,
            acceptedDeadline: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
            forceAssigned: false
        )
    }

    static var previewAccepted: CaptainAssignment {
        CaptainAssignment(
            id: "cap-2",
            areaId: "area-2",
            areaName: "West Gate",
            areaDescription: "West gate area",
            areaCategory: "Exterior",
            departmentId: "dept-1",
            departmentName: "Attendant",
            departmentType: "ATTENDANT",
            eventId: "event-preview",
            sessionId: "session-1",
            sessionName: "Saturday Morning",
            date: Date(),
            startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!,
            status: .accepted,
            respondedAt: Date(),
            declineReason: nil,
            acceptedDeadline: nil,
            forceAssigned: false
        )
    }

    static var previewForceAssigned: CaptainAssignment {
        CaptainAssignment(
            id: "cap-3",
            areaId: "area-3",
            areaName: "Main Entrance",
            areaDescription: nil,
            areaCategory: "Exterior",
            departmentId: "dept-1",
            departmentName: "Attendant",
            departmentType: "ATTENDANT",
            eventId: "event-preview",
            sessionId: "session-2",
            sessionName: "Saturday Afternoon",
            date: Date(),
            startTime: Calendar.current.date(bySettingHour: 13, minute: 30, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 16, minute: 30, second: 0, of: Date())!,
            status: .accepted,
            respondedAt: Date(),
            declineReason: nil,
            acceptedDeadline: nil,
            forceAssigned: true
        )
    }
}
