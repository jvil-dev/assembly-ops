//
//  Volunteer.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 1/3/26.
//

// MARK: - Volunteer Model
//
// Local model representing volunteer profile data.
// Parsed from GraphQL MyVolunteerProfileQuery response.
//
// Properties:
//   - id, volunteerId: Unique identifiers
//   - firstName, lastName, congregation: Basic info
//   - phone, email, appointmentStatus: Contact and status
//   - departmentId/Name/Type: Assigned department (optional)
//   - eventId/Name/Venue/Address/Dates: Event details
//
// Computed Properties:
//   - fullName: "First Last" format
//   - initials: "FL" format for avatar
//   - departmentColor: Color based on department type
//   - eventDateRange: Formatted date range string
//
// Used by: ProfileViewModel, ProfileView

import Foundation
import SwiftUI

struct Volunteer: Identifiable {
    let id: String
    let volunteerId: String
    let firstName: String
    let lastName: String
    let congregation: String
    let phone: String?
    let email: String?
    let appointmentStatus: String?
    let departmentId: String?
    let departmentName: String?
    let departmentType: String?
    let eventId: String
    let eventName: String
    let eventVenue: String?
    let eventAddress: String?
    let eventStartDate: Date?
    let eventEndDate: Date?
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var initials: String {
        let first = firstName.prefix(1).uppercased()
        let last = lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }
    
    var departmentColor: Color {
        guard let type = departmentType
        else {
            return Color(.systemGray)
        }
        return DepartmentColor.color(for: type)
    }
    
    var eventDateRange: String? {
        guard let start = eventStartDate,
              let end = eventEndDate
                else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}
