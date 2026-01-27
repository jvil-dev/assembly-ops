//
//  DeclinedAssignment.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/26/26.
//

// MARK: - Declined Assignment
//
// Model representing a declined assignment for overseer reassignment view.
// Contains volunteer, post, and session info along with decline details.
//
// Properties:
//   - id: Assignment ID
//   - status: Assignment status (DECLINED or AUTO_DECLINED)
//   - declineReason: Optional reason provided by volunteer
//   - respondedAt: When the volunteer declined
//   - volunteerName: Full name for display
//   - postName: Post being declined
//   - sessionName/date: Session details
//
// Used by: DeclinedAssignmentsView, DeclinedAssignmentsViewModel

import Foundation

struct DeclinedAssignment: Identifiable {
    let id: String
    let status: AssignmentStatus
    let declineReason: String?
    let respondedAt: Date?
    let volunteerId: String
    let volunteerName: String
    let volunteerCongregation: String
    let postId: String
    let postName: String
    let postLocation: String?
    let departmentId: String
    let departmentName: String
    let sessionId: String
    let sessionName: String
    let date: String
    let startTime: String
    let endTime: String
}

extension DeclinedAssignment {
    init(from graphQL: AssemblyOpsAPI.DeclinedAssignmentsQuery.Data.DeclinedAssignment) {
        self.id = graphQL.id
        self.status = AssignmentStatus(rawValue: graphQL.status.rawValue) ?? .declined
        self.declineReason = graphQL.declineReason

        if let respondedAtString = graphQL.respondedAt {
            self.respondedAt = DateUtils.isoFormatter.date(from: respondedAtString)
        } else {
            self.respondedAt = nil
        }

        self.volunteerId = graphQL.volunteer.id
        self.volunteerName = "\(graphQL.volunteer.firstName) \(graphQL.volunteer.lastName)"
        self.volunteerCongregation = graphQL.volunteer.congregation
        self.postId = graphQL.post.id
        self.postName = graphQL.post.name
        self.postLocation = graphQL.post.location
        self.departmentId = graphQL.post.department.id
        self.departmentName = graphQL.post.department.name
        self.sessionId = graphQL.session.id
        self.sessionName = graphQL.session.name
        self.date = graphQL.session.date
        self.startTime = graphQL.session.startTime
        self.endTime = graphQL.session.endTime
    }
}
