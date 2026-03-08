//
//  Assignment.swift
//  AssemblyOps
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

/// Assignment status for acceptance workflow
enum AssignmentStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case accepted = "ACCEPTED"
    case declined = "DECLINED"
    case autoDeclined = "AUTO_DECLINED"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        case .autoDeclined: return "Auto-Declined"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "yellow"
        case .accepted: return "green"
        case .declined, .autoDeclined: return "red"
        }
    }
}
/// Check-in status matching backend enum
enum CheckInStatus: String, Codable, Equatable {
    case pending = "PENDING"
    case checkedIn = "CHECKED_IN"
    case checkedOut = "CHECKED_OUT"
    case noShow = "NO_SHOW"
}

/// Local model for assignment data
struct Assignment: Identifiable, Equatable {
    let id: String
    let postName: String
    let postLocation: String?
    let postId: String
    let postCategory: String?
    let areaId: String?
    let areaName: String?
    let departmentName: String
    let departmentType: String
    let eventId: String
    let sessionName: String
    let sessionId: String
    let date: Date
    let startTime: Date
    let endTime: Date

    // Shift times (for Attendant assignments with post-specific shifts)
    let shiftId: String?
    let shiftName: String?
    let shiftStartTime: Date?
    let shiftEndTime: Date?

    // Assignment status
    var status: AssignmentStatus
    var isCaptain: Bool
    var canCount: Bool
    var respondedAt: Date?
    var declineReason: String?
    var acceptDeadline: Date?
    var forceAssigned: Bool
    
    // Check-in status (attendance tracking)
    let checkInStatus: CheckInStatus
    let checkInTime: Date?
    let checkOutTime: Date?
    
    
    // MARK: - Computed Properties

    var isToday: Bool {
        DateUtils.isSessionDateToday(date)
    }

    var isUpcoming: Bool {
        date > Date()
    }

    var isPending: Bool {
        status == .pending
    }

    var isAccepted: Bool {
        status == .accepted
    }

    var canRespond: Bool {
        status == .pending && !forceAssigned
    }

    var deadlineText: String? {
        guard let deadline = acceptDeadline, status == .pending else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        if days <= 0 {
            return "Respond today"
        } else if days == 1 {
            return "1 day to respond"
        } else {
            return "\(days) days to respond"
        }
    }

    var canCheckIn: Bool {
        guard status == .accepted else { return false }
        guard isToday else { return false }
        return checkInStatus == .pending
    }

    var canCheckOut: Bool {
        checkInStatus == .checkedIn
    }

    var isCheckedIn: Bool {
        checkInStatus == .checkedIn
    }

    var isCheckedOut: Bool {
        checkInStatus == .checkedOut
    }

    /// Whether this assignment belongs to an AV department (Audio, Video, or Stage)
    var isAVDepartment: Bool {
        ["AUDIO", "VIDEO", "STAGE"].contains(departmentType.uppercased())
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

    /// Whether this is an Attendant assignment that has a specific shift time
    var hasShift: Bool {
        departmentType.uppercased() == "ATTENDANT" && shiftStartTime != nil && shiftEndTime != nil
    }

    /// The effective start time for display and sorting: shift time if available, otherwise session time
    var displayStartTime: Date {
        hasShift ? shiftStartTime! : startTime
    }

    /// The effective end time for display: shift time if available, otherwise session time
    var displayEndTime: Date {
        hasShift ? shiftEndTime! : endTime
    }

    /// Formatted time range for display (uses shift times for Attendant assignments with shifts)
    var timeRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: displayStartTime)) - \(formatter.string(from: displayEndTime))"
    }
}

// MARK: - GraphQL Mapping
extension Assignment {
    init?(from graphQL: AssemblyOpsAPI.MyAssignmentsQuery.Data.MyAssignment) {
        self.id = graphQL.id
        self.postName = graphQL.post.name
        self.postLocation = graphQL.post.location
        self.postId = graphQL.post.id
        self.postCategory = graphQL.post.category
        self.areaId = graphQL.post.area?.id
        self.areaName = graphQL.post.area?.name
        self.departmentName = graphQL.post.department.name
        self.departmentType = graphQL.post.department.departmentType.rawValue
        self.eventId = graphQL.post.department.event.id
        self.sessionName = graphQL.session.name
        self.sessionId = graphQL.session.id

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

        // Parse optional shift times
        if let shift = graphQL.shift {
            self.shiftId = shift.id
            self.shiftName = shift.name
            self.shiftStartTime = isoFormatter.date(from: shift.startTime)
            self.shiftEndTime = isoFormatter.date(from: shift.endTime)
        } else {
            self.shiftId = nil
            self.shiftName = nil
            self.shiftStartTime = nil
            self.shiftEndTime = nil
        }

        // Assignment acceptance workflow fields
        self.status = AssignmentStatus(rawValue: graphQL.status.rawValue) ?? .pending
        self.isCaptain = graphQL.isCaptain
        self.canCount = graphQL.canCount
        self.respondedAt = graphQL.respondedAt.flatMap { isoFormatter.date(from: $0) }
        self.declineReason = graphQL.declineReason
        self.acceptDeadline = graphQL.acceptDeadline.flatMap { isoFormatter.date(from: $0) }
        self.forceAssigned = graphQL.forceAssigned

        // Check-in status
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
            postId: "post-1",
            postCategory: "Interior",
            areaId: "area-1",
            areaName: "East Wing",
            departmentName: "Attendant",
            departmentType: "ATTENDANT",
            eventId: "event-preview",
            sessionName: "Saturday Morning",
            sessionId: "session-1",
            date: Date(),
            startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!,
            shiftId: nil,
            shiftName: nil,
            shiftStartTime: nil,
            shiftEndTime: nil,
            status: .accepted,
            isCaptain: false,
            canCount: false,
            respondedAt: nil,
            declineReason: nil,
            acceptDeadline: nil,
            forceAssigned: false,
            checkInStatus: .pending,
            checkInTime: nil,
            checkOutTime: nil
        )
    }

    static var previewPending: Assignment {
        Assignment(
            id: "6",
            postName: "West Gate",
            postLocation: "Building C",
            postId: "post-6",
            postCategory: "Exterior",
            areaId: "area-2",
            areaName: "West Gate Area",
            departmentName: "Attendant",
            departmentType: "ATTENDANT",
            eventId: "event-preview",
            sessionName: "Saturday Morning",
            sessionId: "session-1",
            date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
            startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!,
            shiftId: nil,
            shiftName: nil,
            shiftStartTime: nil,
            shiftEndTime: nil,
            status: .pending,
            isCaptain: false,
            canCount: false,
            respondedAt: nil,
            declineReason: nil,
            acceptDeadline: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
            forceAssigned: false,
            checkInStatus: .pending,
            checkInTime: nil,
            checkOutTime: nil
        )
    }

    static var previewCaptain: Assignment {
        Assignment(
            id: "7",
            postName: "Main Entrance",
            postLocation: "Building A",
            postId: "post-7",
            postCategory: "Exterior",
            areaId: "area-3",
            areaName: "Main Entrance Area",
            departmentName: "Attendant",
            departmentType: "ATTENDANT",
            eventId: "event-preview",
            sessionName: "Saturday Morning",
            sessionId: "session-1",
            date: Date(),
            startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!,
            shiftId: nil,
            shiftName: nil,
            shiftStartTime: nil,
            shiftEndTime: nil,
            status: .accepted,
            isCaptain: true,
            canCount: false,
            respondedAt: Date(),
            declineReason: nil,
            acceptDeadline: nil,
            forceAssigned: false,
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
            postId: "post-2",
            postCategory: "Seating",
            areaId: "area-4",
            areaName: "Main Hall Area",
            departmentName: "Attendant",
            departmentType: "ATTENDANT",
            eventId: "event-preview",
            sessionName: "Saturday Afternoon",
            sessionId: "session-2",
            date: Date(),
            startTime: Calendar.current.date(bySettingHour: 13, minute: 30, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 16, minute: 30, second: 0, of: Date())!,
            shiftId: nil,
            shiftName: nil,
            shiftStartTime: nil,
            shiftEndTime: nil,
            status: .accepted,
            isCaptain: false,
            canCount: false,
            respondedAt: Date(),
            declineReason: nil,
            acceptDeadline: nil,
            forceAssigned: false,
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
            postId: "post-3",
            postCategory: "Interior",
            areaId: "area-1",
            areaName: "East Wing",
            departmentName: "Attendant",
            departmentType: "ATTENDANT",
            eventId: "event-preview",
            sessionName: "Saturday Morning",
            sessionId: "session-1",
            date: Date(),
            startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!,
            shiftId: nil,
            shiftName: nil,
            shiftStartTime: nil,
            shiftEndTime: nil,
            status: .accepted,
            isCaptain: false,
            canCount: false,
            respondedAt: Date(),
            declineReason: nil,
            acceptDeadline: nil,
            forceAssigned: false,
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
            postId: "post-4",
            postCategory: nil,
            areaId: nil,
            areaName: nil,
            departmentName: "Parking",
            departmentType: "PARKING",
            eventId: "event-preview",
            sessionName: "Sunday Morning",
            sessionId: "session-3",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            startTime: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!,
            shiftId: nil,
            shiftName: nil,
            shiftStartTime: nil,
            shiftEndTime: nil,
            status: .accepted,
            isCaptain: false,
            canCount: false,
            respondedAt: Date(),
            declineReason: nil,
            acceptDeadline: nil,
            forceAssigned: false,
            checkInStatus: .noShow,
            checkInTime: nil,
            checkOutTime: nil
        )
    }

    static var previewParking: Assignment {
        Assignment(
            id: "5",
            postName: "Lot A",
            postLocation: "North Gate",
            postId: "post-5",
            postCategory: nil,
            areaId: nil,
            areaName: nil,
            departmentName: "Parking",
            departmentType: "PARKING",
            eventId: "event-preview",
            sessionName: "Friday Afternoon",
            sessionId: "session-4",
            date: Date(),
            startTime: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: Date())!,
            shiftId: nil,
            shiftName: nil,
            shiftStartTime: nil,
            shiftEndTime: nil,
            status: .accepted,
            isCaptain: false,
            canCount: false,
            respondedAt: nil,
            declineReason: nil,
            acceptDeadline: nil,
            forceAssigned: false,
            checkInStatus: .pending,
            checkInTime: nil,
            checkOutTime: nil
        )
    }
}

// MARK: - Hashable Conformance for Navigation
  extension Assignment: Hashable {
      func hash(into hasher: inout Hasher) {
          hasher.combine(id)
      }

      static func == (lhs: Assignment, rhs: Assignment) -> Bool {
          lhs.id == rhs.id &&
          lhs.status == rhs.status &&
          lhs.canCount == rhs.canCount &&
          lhs.checkInStatus == rhs.checkInStatus &&
          lhs.checkInTime == rhs.checkInTime &&
          lhs.checkOutTime == rhs.checkOutTime
      }
  }
