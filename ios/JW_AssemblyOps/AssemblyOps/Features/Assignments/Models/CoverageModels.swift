//
//  CoverageModels.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Coverage Models
//
// Data models for the department coverage matrix feature.
// Used by CoverageMatrixViewModel and AssignmentsView for scheduling display.
//
// Types:
//   - CoverageShift: Shift time block within a slot
//   - CoverageSlot: Post + Session combination with shift and assignment data
//   - CoverageAssignment: Single volunteer assignment within a slot
//   - CoverageVolunteer: Lightweight volunteer info for coverage display
//   - CoverageCheckInInfo: Check-in timestamp data
//   - CoveragePost: Post location within a department
//   - CoverageSession: Time block for scheduling
//
// Data Flow:
//   1. DepartmentCoverageQuery returns flat list of slots
//   2. CoverageMatrixViewModel maps response to these models
//   3. AssignmentsView renders grid using posts × sessions matrix
//

import Foundation

struct CoverageShift: Identifiable, Equatable {
    let id: String
    let name: String
    let startTime: String
    let endTime: String

    var timeRangeDisplay: String {
        let start = Self.formatTimeField(startTime)
        let end = Self.formatTimeField(endTime)
        return "\(start) – \(end)"
    }

    private static func formatTimeField(_ timeString: String) -> String {
        if let date = DateUtils.parseISO8601(timeString) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return timeString
    }
}

struct CoverageSlot: Identifiable, Equatable {
    var id: String { "\(postId)-\(sessionId)" }
    let postId: String
    let sessionId: String
    let postName: String
    let sessionName: String
    let shifts: [CoverageShift]
    let assignments: [CoverageAssignment]
    let filled: Int

    var pendingCount: Int { assignments.filter { $0.isPending }.count }

    static func == (lhs: CoverageSlot, rhs: CoverageSlot) -> Bool {
        lhs.postId == rhs.postId &&
        lhs.sessionId == rhs.sessionId &&
        lhs.postName == rhs.postName &&
        lhs.sessionName == rhs.sessionName &&
        lhs.shifts == rhs.shifts &&
        lhs.assignments == rhs.assignments &&
        lhs.filled == rhs.filled
    }
}

struct CoverageAssignment: Identifiable, Equatable {
    let id: String
    let volunteer: CoverageVolunteer
    let checkIn: CoverageCheckInInfo?
    let status: AssignmentStatus
    let forceAssigned: Bool
    let shiftId: String?
    let shiftName: String?

    var isPending: Bool { status == .pending }
    var isAccepted: Bool { status == .accepted }
}

struct CoverageVolunteer: Equatable {
    let id: String
    let firstName: String
    let lastName: String
}

struct CoverageCheckInInfo: Equatable {
    let id: String
    let checkInTime: Date
}

struct CoveragePost: Identifiable {
    let id: String
    let name: String
    let category: String?
    let location: String?
    let sortOrder: Int
    let areaId: String?
    let areaName: String?
}

struct CoverageSession: Identifiable {
    let id: String
    let name: String
    let date: Date
    let startTime: Date
    let endTime: Date
}
