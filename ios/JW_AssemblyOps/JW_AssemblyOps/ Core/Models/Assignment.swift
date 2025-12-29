//
//  Assignment.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Assignment Model
//
// Local model representing a volunteer's schedule assignment.
// Parsed from GraphQL MyAssignmentsQuery response.
//
// Properties:
//   - id: Unique assignment ID
//   - postName: Name of the assigned post (e.g., "East Lobby")
//   - postLocation: Optional location details (e.g., "Building A, Floor 1")
//   - departmentName: Department name (e.g., "Attendant")
//   - sessionName: Session name (e.g., "Saturday Morning")
//   - date: Date of the assignment
//   - startTime/endTime: Session time range
//   - isCheckedIn: Whether volunteer has checked in
//   - checkInTime: When volunteer checked in (nil if not checked in)
//
// Computed Properties:
//   - dateFormatted: Human-readable date string
//   - timeRangeFormatted: "9:00 AM - 12:00 PM" format
//   - isToday/isUpcoming/isPast: Date classification helpers
//
// GraphQL Mapping:
//   - init?(from:) failable initializer parses ISO8601 dates from API response
//
// Used by: AssignmentsViewModel, AssignmentCardView, AssignmentDetailView

import Foundation

/// Local model for assignment data
struct Assignment: Identifiable {
    let id: String
    let postName: String
    let postLocation: String?
    let departmentName: String
    let sessionName: String
    let date: Date
    let startTime: Date
    let endTime: Date
    let isCheckedIn: Bool
    let checkInTime: Date?
    
    var dateFormatted: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
    
    var timeRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var isUpcoming: Bool {
        date >= Calendar.current.startOfDay(for: Date())
    }
    
    var isPast: Bool {
        date < Calendar.current.startOfDay(for: Date())
    }
}

// MARK: - GraphQL Mapping
extension Assignment {
      init?(from graphQL: AssemblyOpsAPI.MyAssignmentsQuery.Data.MyAssignment) {
          self.id = graphQL.id
          self.postName = graphQL.post.name
          self.postLocation = graphQL.post.location
          self.departmentName = graphQL.post.department.name
          self.sessionName = graphQL.session.name
          self.isCheckedIn = graphQL.isCheckedIn

          // Parse dates from ISO8601 strings
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

          // Parse optional checkIn time
          if let checkInTimeStr = graphQL.checkIn?.checkInTime {
              self.checkInTime = isoFormatter.date(from: checkInTimeStr)
          } else {
              self.checkInTime = nil
          }
      }
  }
