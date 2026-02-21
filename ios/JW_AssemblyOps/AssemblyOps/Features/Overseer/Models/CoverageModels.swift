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
//   - CoverageSlot: Post + Session combination with assignment data
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

struct CoverageSlot: Identifiable, Equatable {
    var id: String { "\(postId)-\(sessionId)" }
    let postId: String
    let sessionId: String
    let postName: String
    let sessionName: String
    let assignments: [CoverageAssignment]
    let filled: Int
    let capacity: Int
    let isFilled: Bool

    var pendingCount: Int { assignments.filter { $0.isPending }.count }

    static func == (lhs: CoverageSlot, rhs: CoverageSlot) -> Bool {
        lhs.postId == rhs.postId &&
        lhs.sessionId == rhs.sessionId &&
        lhs.postName == rhs.postName &&
        lhs.sessionName == rhs.sessionName &&
        lhs.assignments == rhs.assignments &&
        lhs.filled == rhs.filled &&
        lhs.capacity == rhs.capacity &&
        lhs.isFilled == rhs.isFilled
    }
}

struct CoverageAssignment: Identifiable, Equatable {
    let id: String
    let volunteer: CoverageVolunteer
    let checkIn: CoverageCheckInInfo?
    let status: AssignmentStatus
    let forceAssigned: Bool

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
    let capacity: Int
    let category: String?
    let location: String?
    let sortOrder: Int
}

struct CoverageSession: Identifiable {
    let id: String
    let name: String
    let date: Date
    let startTime: Date
    let endTime: Date
}
