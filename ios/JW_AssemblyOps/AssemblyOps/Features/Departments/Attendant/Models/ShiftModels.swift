//
//  ShiftModels.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/1/26.
//

// MARK: - Shift Models
//
// Data models for the Shift feature.
// Shifts are post-specific time blocks that subdivide sessions
// into smaller duty periods (e.g., 1-hour exterior shifts).
//
// Types:
//   - ShiftAssignment: A volunteer assigned to a shift
//   - ShiftItem: A named time block for a specific post within a session
//
// Data Flow:
//   1. GraphQL queries return Apollo generated types
//   2. init(from:) mappers convert to this domain model
//   3. ShiftManagementViewModel exposes these types to Views
//

import Foundation

// MARK: - Shift Assignment

struct ShiftAssignment: Identifiable {
    let id: String
    let eventVolunteerId: String
    let volunteerName: String
    let status: String
    let isCheckedIn: Bool
}

// MARK: - Shift Item

struct ShiftItem: Identifiable {
    let id: String
    let sessionId: String
    let postId: String
    let name: String
    /// Raw time string from the backend (ISO 8601 DateTime, e.g., "1970-01-01T07:45:00.000Z")
    let startTime: String
    /// Raw time string from the backend (ISO 8601 DateTime, e.g., "1970-01-01T08:45:00.000Z")
    let endTime: String
    let sessionName: String?
    let postName: String?
    let createdAt: Date?
    let createdByName: String?
    var assignments: [ShiftAssignment]
}

extension ShiftItem {
    init(from data: AssemblyOpsAPI.ShiftsQuery.Data.Shift) {
        self.id = data.id
        self.sessionId = data.session.id
        self.postId = data.post.id
        self.name = data.name
        self.startTime = data.startTime
        self.endTime = data.endTime
        self.sessionName = data.session.name
        self.postName = data.post.name
        self.createdAt = DateUtils.parseISO8601(data.createdAt)
        if let creator = data.createdBy {
            self.createdByName = "\(creator.firstName) \(creator.lastName)"
        } else {
            self.createdByName = nil
        }
        self.assignments = data.assignments.compactMap { assignment in
            guard let ev = assignment.eventVolunteer else { return nil }
            return ShiftAssignment(
                id: assignment.id,
                eventVolunteerId: ev.id,
                volunteerName: "\(ev.user.firstName) \(ev.user.lastName)",
                status: assignment.status.rawValue,
                isCheckedIn: assignment.checkIn != nil
            )
        }
    }

    init(fromCaptain data: AssemblyOpsAPI.CaptainShiftsQuery.Data.CaptainShift) {
        self.id = data.id
        self.sessionId = data.session.id
        self.postId = data.post.id
        self.name = data.name
        self.startTime = data.startTime
        self.endTime = data.endTime
        self.sessionName = data.session.name
        self.postName = data.post.name
        self.createdAt = DateUtils.parseISO8601(data.createdAt)
        if let creator = data.createdBy {
            self.createdByName = "\(creator.firstName) \(creator.lastName)"
        } else {
            self.createdByName = nil
        }
        self.assignments = data.assignments.compactMap { assignment in
            guard let ev = assignment.eventVolunteer else { return nil }
            return ShiftAssignment(
                id: assignment.id,
                eventVolunteerId: ev.id,
                volunteerName: "\(ev.user.firstName) \(ev.user.lastName)",
                status: assignment.status.rawValue,
                isCheckedIn: assignment.checkIn != nil
            )
        }
    }

    init(fromCreate data: AssemblyOpsAPI.CreateShiftMutation.Data.CreateShift) {
        self.id = data.id
        self.sessionId = data.session.id
        self.postId = data.post.id
        self.name = data.name
        self.startTime = data.startTime
        self.endTime = data.endTime
        self.sessionName = data.session.name
        self.postName = data.post.name
        self.createdAt = DateUtils.parseISO8601(data.createdAt)
        if let creator = data.createdBy {
            self.createdByName = "\(creator.firstName) \(creator.lastName)"
        } else {
            self.createdByName = nil
        }
        self.assignments = []
    }

    init(fromUpdate data: AssemblyOpsAPI.UpdateShiftMutation.Data.UpdateShift) {
        self.id = data.id
        self.sessionId = data.session.id
        self.postId = data.post.id
        self.name = data.name
        self.startTime = data.startTime
        self.endTime = data.endTime
        self.sessionName = data.session.name
        self.postName = data.post.name
        self.createdAt = nil
        self.createdByName = nil
        self.assignments = []
    }

    /// Format shift time range for display (e.g., "7:45 AM – 8:45 AM")
    var timeRangeDisplay: String {
        let start = Self.formatTimeField(startTime)
        let end = Self.formatTimeField(endTime)
        return "\(start) – \(end)"
    }

    /// Extract "HH:mm" from the ISO DateTime string for sending back to the backend
    var startTimeHHmm: String {
        Self.extractHHmm(from: startTime)
    }

    /// Extract "HH:mm" from the ISO DateTime string for sending back to the backend
    var endTimeHHmm: String {
        Self.extractHHmm(from: endTime)
    }

    /// Convert an ISO 8601 DateTime or "HH:mm" time string to a localized time display
    private static func formatTimeField(_ timeString: String) -> String {
        // Try ISO 8601 DateTime first (e.g., "1970-01-01T07:45:00.000Z")
        if let date = DateUtils.parseISO8601(timeString) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }

        // Fallback: try "HH:mm" format
        return formatHHmm(timeString)
    }

    /// Convert "HH:mm" string to localized time display
    private static func formatHHmm(_ timeString: String) -> String {
        let parts = timeString.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return timeString
        }

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        guard let date = Calendar.current.date(from: components) else {
            return timeString
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Extract "HH:mm" from an ISO 8601 DateTime string
    private static func extractHHmm(from dateTimeString: String) -> String {
        if let date = DateUtils.parseISO8601(dateTimeString) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            formatter.timeZone = TimeZone(identifier: "UTC")
            return formatter.string(from: date)
        }
        // Already in HH:mm format
        return dateTimeString
    }
}
