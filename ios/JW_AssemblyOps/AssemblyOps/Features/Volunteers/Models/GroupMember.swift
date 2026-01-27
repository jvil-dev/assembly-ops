//
//  GroupMember.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/26/26.
//

// MARK: - Group Member
//
// Model representing a volunteer in a captain's group.
// Used to display group members and manage captain check-ins.
//
// Properties:
//   - id: Volunteer ID
//   - firstName/lastName: Volunteer name
//   - congregation: Home congregation
//   - phone: Optional phone number
//   - assignmentId: The assignment ID for check-in operations
//   - assignmentStatus: Current assignment status (pending, accepted, etc.)
//   - isCheckedIn: Whether the member has checked in
//   - checkInTime: When the member checked in (nil if not checked in)
//
// Computed Properties:
//   - fullName: Combined first and last name
//   - canCheckIn: True if accepted and not yet checked in
//
// GraphQL Mapping:
//   - init(from:) initializer parses CaptainGroupQuery response
//
// Used by: CaptainGroupView, CaptainGroupViewModel

import Foundation

struct GroupMember: Identifiable, Equatable {
    let id: String
    let firstName: String
    let lastName: String
    let congregation: String
    let phone: String?
    let assignmentId: String
    let assignmentStatus: AssignmentStatus
    let isCheckedIn: Bool
    let checkInTime: Date?
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var canCheckIn: Bool {
        assignmentStatus == .accepted && !isCheckedIn
    }
}

// MARK: - GraphQL Mapping

extension GroupMember {
    /// Initialize from CaptainGroup member (which is a ScheduleAssignment with nested volunteer)
    init(from graphQL: AssemblyOpsAPI.CaptainGroupQuery.Data.CaptainGroup.Member) {
        self.id = graphQL.volunteer.id
        self.firstName = graphQL.volunteer.firstName
        self.lastName = graphQL.volunteer.lastName
        self.congregation = graphQL.volunteer.congregation
        self.phone = graphQL.volunteer.phone
        self.assignmentId = graphQL.id
        self.assignmentStatus = AssignmentStatus(rawValue: graphQL.status.rawValue) ?? .pending
        self.isCheckedIn = graphQL.checkIn?.status.rawValue == "CHECKED_IN"
        if let checkInTimeString = graphQL.checkIn?.checkInTime {
            self.checkInTime = DateUtils.isoFormatter.date(from: checkInTimeString)
        } else {
            self.checkInTime = nil
        }
    }
}
