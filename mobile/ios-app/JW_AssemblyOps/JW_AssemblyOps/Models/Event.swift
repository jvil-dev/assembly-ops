//
//  Event.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/22/25.
//

import Foundation
import SwiftData

@Model
final class Event {
    // MARK: - Properties
    
    @Attribute(.unique) var id: String
    var name: String
    var eventType: EventType
    var circuit: String?
    var date: Date
    var endDate: Date?
    var theme: String
    var scripture: String
    var venueName: String
    var streetAddress: String
    var city: String
    var state: String
    var zip: String
    var language: Language
    
    // Template reference
    var templateId: String?  // EventTemplate this was created from
    
    // Status
    var isActive: Bool
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    var lastSyncedAt: Date?
    
    // MARK: - Relationships
    
    var createdBy: Overseer?
    
    @Relationship(deleteRule: .cascade, inverse: \Department.event)
    var departments: [Department]?
    
    @Relationship(deleteRule: .cascade, inverse: \Volunteer.event)
    var volunteers: [Volunteer]?
    
    @Relationship(deleteRule: .cascade, inverse: \Role.event)
    var roles: [Role]?
    
    @Relationship(deleteRule: .cascade, inverse: \Session.event)
    var sessions: [Session]?
    
    @Relationship(deleteRule: .cascade, inverse: \Assignment.event)
    var assignments: [Assignment]?
    
    @Relationship(deleteRule: .cascade, inverse: \Message.event)
    var messages: [Message]?
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        name: String,
        eventType: EventType,
        circuit: String? = nil,
        date: Date,
        endDate: Date? = nil,
        theme: String,
        scripture: String,
        venueName: String,
        streetAddress: String,
        city: String,
        state: String,
        zip: String,
        language: Language = .english,
        templateId: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.eventType = eventType
        self.circuit = circuit
        self.date = date
        self.endDate = endDate
        self.theme = theme
        self.scripture = scripture
        self.venueName = venueName
        self.streetAddress = streetAddress
        self.city = city
        self.state = state
        self.zip = zip
        self.language = language
        self.templateId = templateId
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var fullAddress: String {
        "\(streetAddress), \(city), \(state) \(zip)"
    }
    
    var displayTitle: String {
        if let circuit = circuit {
            return "\(circuit) - \(name)"
        }
        return name
    }
    
    var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if let endDate = endDate {
            return "\(formatter.string(from: date)) - \(formatter.string(from: endDate))"
        }
        return formatter.string(from: date)
    }
    
    var availableDepartmentTypes: [DepartmentType] {
        DepartmentType.departments(for: eventType)
    }
}
