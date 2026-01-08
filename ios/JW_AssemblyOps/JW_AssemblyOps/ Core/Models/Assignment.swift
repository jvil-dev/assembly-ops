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
//   - checkInStatus: Current status (pending, checkedIn, checkedOut, noShow)
//   - checkInTime: When volunteer checked in (nil if not checked in)
//   - checkOutTime: When volunteer checked out (nil if not checked out)
//
// Computed Properties:
//   - isCheckedIn/isCheckedOut: Boolean status helpers
//   - canCheckIn: True if pending and today
//   - canCheckOut: True if checked in
//   - dateFormatted: Human-readable date string
//   - timeRangeFormatted: "9:00 AM - 12:00 PM" format
//   - isToday/isUpcoming/isPast: Date classification helpers
//   - statusText/statusColor: Display helpers for UI
//
// GraphQL Mapping:
//   - init?(from:) failable initializer parses ISO8601 dates and status from API response
//
// Preview Data:
//   - .preview, .previewCheckedIn, .previewCheckedOut, .previewNoShow
//
// Used by: AssignmentsViewModel, AssignmentCardView, AssignmentDetailView, CheckInButton

import Foundation
import SwiftUI

/// Check-in status matching backend enum
enum CheckInStatus: String {
    case checkedIn = "CHECKED_IN"
    case checkedOut = "CHECKED_OUT"
    case noShow = "NO_SHOW"
    case pending
}

/// Local model for assignment data
struct Assignment: Identifiable {
    let id: String
    let postName: String
    let postLocation: String?
    let departmentName: String
    let departmentType: String
    let sessionName: String
    let date: Date
    let startTime: Date
    let endTime: Date
    let checkInStatus: CheckInStatus
    let checkInTime: Date?
    let checkOutTime: Date?
    
    var isCheckedIn: Bool {
        checkInStatus == .checkedIn
    }
    
    var isCheckedOut: Bool {
        checkInStatus == .checkedOut
    }
    
    var canCheckIn: Bool {
        checkInStatus == .pending && isToday
    }
    
    var canCheckOut: Bool {
        checkInStatus == .checkedIn
    }
    
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
    
    /// Status display text
    var statusText: String {
        switch checkInStatus {
        case .checkedIn:
            return "Checked In"
        case .checkedOut:
            return "Checked Out"
        case .noShow:
            return "No Show"
        case .pending:
            return isToday ? "Not Checked In" : ""
        }
    }
    
    /// Status color
    var statusColor: String {
        switch checkInStatus {
        case .checkedIn:
            return "green"
        case .checkedOut:
            return "blue"
        case .noShow:
            return "red"
        case .pending:
            return "gray"
        }
    }
    
    /// Department color based on lanyard
    var departmentColor: Color {
        DepartmentColor.color(for: departmentType)
    }
    
    /// Department background color
    var departmentBackgroundColor: Color {
        DepartmentColor.backgroundColor(for: departmentType)
    }
}

// MARK: - GraphQL Mapping
extension Assignment {
      init?(from graphQL: AssemblyOpsAPI.MyAssignmentsQuery.Data.MyAssignment) {
          self.id = graphQL.id
          self.postName = graphQL.post.name
          self.postLocation = graphQL.post.location
          self.departmentName = graphQL.post.department.name
          self.departmentType = graphQL.post.department.departmentType.rawValue
          self.sessionName = graphQL.session.name

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

          if let checkIn = graphQL.checkIn {
              self.checkInStatus = CheckInStatus(rawValue: checkIn.status.rawValue) ?? .pending
              self.checkInTime = isoFormatter.date(from: checkIn.checkInTime)
              self.checkOutTime = checkIn.checkOutTime.flatMap { isoFormatter.date(from: $0) }
          } else {
              self.checkInStatus = .pending
              self.checkInTime = nil
              self.checkOutTime = nil
          }
      }
  }

// MARK: - Preview Data
extension Assignment {
    static var preview: Assignment {
        Assignment(
            id: "1",
            postName: "East Lobby",
            postLocation: "Building A, Floor 1",
            departmentName: "Attendant",
            departmentType: "ATTENDANT",
            sessionName: "Saturday Morning",
            date: Date(),
            startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!,
            checkInStatus: .pending,
            checkInTime: nil,
            checkOutTime: nil
        )
    }
    
    static var previewCheckedIn: Assignment {
        Assignment(
            id: "2",
            postName: "Auditorium",
            postLocation: "Main Hall",
            departmentName: "Attendant",
            departmentType: "ATTENDANT",
            sessionName: "Saturday Afternoon",
            date: Date(),
            startTime: Calendar.current.date(bySettingHour: 13, minute: 30, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 16, minute: 30, second: 0, of: Date())!,
            checkInStatus: .checkedIn,
            checkInTime: Date(),
            checkOutTime: nil
        )
    }
    
    static var previewCheckedOut: Assignment {
        Assignment(
            id: "3",
            postName: "West Lobby",
            postLocation: "Building B",
            departmentName: "Attendant",
            departmentType: "ATTENDANT",
            sessionName: "Saturday Morning",
            date: Date(),
            startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!,
            checkInStatus: .checkedOut,
            checkInTime: Calendar.current.date(bySettingHour: 8, minute: 55, second: 0, of: Date()),
            checkOutTime: Calendar.current.date(bySettingHour: 12, minute: 5, second: 0, of: Date())
        )
    }
    
    static var previewNoShow: Assignment {
        Assignment(
            id: "4",
            postName: "Parking Lot A",
            postLocation: "North Entrance",
            departmentName: "Parking",
            departmentType: "PARKING",
            sessionName: "Sunday Morning",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            startTime: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!,
            checkInStatus: .noShow,
            checkInTime: nil,
            checkOutTime: nil
        )
    }
    
    static var previewParking: Assignment {
        Assignment(id: "5", postName: "Lot A", postLocation: "North Gate", departmentName: "Parking", departmentType: "PARKING", sessionName: "Friday Afternoon", date: Date(), startTime: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date())!, endTime: Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: Date())!, checkInStatus: .pending, checkInTime: nil, checkOutTime: nil)
    }
}

// MARK: - Hashable Conformance for Navigation
  extension Assignment: Hashable {
      func hash(into hasher: inout Hasher) {
          hasher.combine(id)
      }

      static func == (lhs: Assignment, rhs: Assignment) -> Bool {
          lhs.id == rhs.id
      }
  }
