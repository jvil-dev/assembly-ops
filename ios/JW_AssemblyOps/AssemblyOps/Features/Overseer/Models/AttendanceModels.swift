//
//  AttendanceModels.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/8/26.
//

// MARK: - Attendance Models
//
// Local models for attendance data from GraphQL API.
//
// Types:
//   - AttendanceCountItem: Individual attendance count with section and notes
//   - SessionAttendanceSummaryItem: Aggregated attendance data for a session
//
// Usage:
//   - Used by AttendanceViewModel and AttendanceService
//   - Conforms to Identifiable for SwiftUI lists

import Foundation

struct AttendanceCountItem: Identifiable {
    let id: String
    let count: Int
    let section: String?
    let notes: String?
    let sessionId: String
    let sessionName: String
    let submittedByName: String
    let createdAt: Date
    let updatedAt: Date
}

struct SessionAttendanceSummaryItem: Identifiable {
    var id: String { sessionId }
    let sessionId: String
    let sessionName: String
    let sessionDate: Date
    let sessionStartTime: Date
    let sessionEndTime: Date
    let totalCount: Int
    let sectionCounts: [AttendanceCountItem]
}

// MARK: - GraphQL Mapping
extension AttendanceCountItem {
    init?(from graphQL: AssemblyOpsAPI.SessionAttendanceCountsQuery.Data.SessionAttendanceCount) {
        self.id = graphQL.id
        self.count = graphQL.count
        self.section = graphQL.section
        self.notes = graphQL.notes

        self.sessionId = graphQL.session.id
        self.sessionName = graphQL.session.name

        let submittedBy = graphQL.submittedBy
        self.submittedByName = "\(submittedBy.firstName) \(submittedBy.lastName)"

        let isoFormatter = DateUtils.isoFormatter

        guard let createdAt = isoFormatter.date(from: graphQL.createdAt) else {
            return nil
        }
        self.createdAt = createdAt

        guard let updatedAt = isoFormatter.date(from: graphQL.updatedAt) else {
            return nil
        }
        self.updatedAt = updatedAt
    }

    // Overload for EventAttendanceSummary nested section counts
    init?(from graphQL: AssemblyOpsAPI.EventAttendanceSummaryQuery.Data.EventAttendanceSummary.SectionCount, sessionId: String, sessionName: String) {
        self.id = graphQL.id
        self.count = graphQL.count
        self.section = graphQL.section
        self.notes = graphQL.notes
        self.sessionId = sessionId
        self.sessionName = sessionName

        let submittedBy = graphQL.submittedBy
        self.submittedByName = "\(submittedBy.firstName) \(submittedBy.lastName)"

        let isoFormatter = DateUtils.isoFormatter

        guard let createdAt = isoFormatter.date(from: graphQL.createdAt) else {
            return nil
        }
        self.createdAt = createdAt

        guard let updatedAt = isoFormatter.date(from: graphQL.updatedAt) else {
            return nil
        }
        self.updatedAt = updatedAt
    }

    // Overload for SubmitAttendanceCount mutation response
    init?(from graphQL: AssemblyOpsAPI.SubmitAttendanceCountMutation.Data.SubmitAttendanceCount) {
        self.id = graphQL.id
        self.count = graphQL.count
        self.section = graphQL.section
        self.notes = graphQL.notes

        self.sessionId = graphQL.session.id
        self.sessionName = graphQL.session.name

        // SubmitAttendanceCount doesn't return submittedBy
        self.submittedByName = "You"

        let isoFormatter = DateUtils.isoFormatter
        guard let createdAt = isoFormatter.date(from: graphQL.createdAt) else {
            return nil
        }
        self.createdAt = createdAt
        self.updatedAt = createdAt // Use createdAt since updatedAt not returned
    }
}

extension SessionAttendanceSummaryItem {
    init?(from graphQL: AssemblyOpsAPI.EventAttendanceSummaryQuery.Data.EventAttendanceSummary) {
        let session = graphQL.session
        self.sessionId = session.id
        self.sessionName = session.name

        let isoFormatter = DateUtils.isoFormatter

        guard let sessionDate = isoFormatter.date(from: session.date) else {
            return nil
        }
        self.sessionDate = sessionDate

        guard let sessionStartTime = isoFormatter.date(from: session.startTime) else {
            return nil
        }
        self.sessionStartTime = sessionStartTime

        guard let sessionEndTime = isoFormatter.date(from: session.endTime) else {
            return nil
        }
        self.sessionEndTime = sessionEndTime

        self.totalCount = graphQL.totalCount

        // Map section counts
        self.sectionCounts = graphQL.sectionCounts.compactMap {
            AttendanceCountItem(from: $0, sessionId: session.id, sessionName: session.name)
        }
    }
}
