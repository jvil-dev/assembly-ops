//
//  Volunteer.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/22/25.
//


import Foundation
import SwiftData

@Model
final class Volunteer {
    // MARK: - Properties
    
    @Attribute(.unique) var id: String
    var odid: String  // 8-character volunteer ID for login
    var token: String  // 16-character token for login
    var firstName: String
    var lastName: String
    var congregation: String
    var appointment: Appointment
    var phone: String?
    var email: String?
    var notes: String?
    
    // Status
    var isActive: Bool
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    var lastSyncedAt: Date?
    
    // MARK: - Relationships
    
    var event: Event?
    var department: Department?
    var role: Role?
    
    @Relationship(deleteRule: .cascade, inverse: \ScheduleAssignment.volunteer)
    var scheduleAssignments: [ScheduleAssignment]?
    
    @Relationship(deleteRule: .cascade, inverse: \CheckIn.volunteer)
    var checkIns: [CheckIn]?
    
    @Relationship(deleteRule: .cascade, inverse: \MessageRecipient.volunteer)
    var messageRecipients: [MessageRecipient]?
    
    @Relationship(deleteRule: .cascade, inverse: \VolunteerAvailability.volunteer)
    var availabilities: [VolunteerAvailability]?
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        odid: String,
        token: String,
        firstName: String,
        lastName: String,
        congregation: String,
        appointment: Appointment = .publisher,
        phone: String? = nil,
        email: String? = nil,
        notes: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.odid = odid
        self.token = token
        self.firstName = firstName
        self.lastName = lastName
        self.congregation = congregation
        self.appointment = appointment
        self.phone = phone
        self.email = email
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var displayName: String {
        "\(lastName), \(firstName)"
    }
    
    var initials: String {
        let firstInitial = firstName.prefix(1).uppercased()
        let lastInitial = lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
}
