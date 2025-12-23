//
//  Session.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/22/25.
//


import Foundation
import SwiftData

@Model
final class Session {
    // MARK: - Properties
    
    @Attribute(.unique) var id: String
    var name: String  // e.g., "Friday Morning", "Saturday Afternoon"
    var date: Date
    var startTime: Date
    var endTime: Date
    var displayOrder: Int
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    var lastSyncedAt: Date?
    
    // MARK: - Relationships
    
    var event: Event?
    
    @Relationship(deleteRule: .cascade, inverse: \ScheduleAssignment.session)
    var scheduleAssignments: [ScheduleAssignment]?
    
    @Relationship(deleteRule: .cascade, inverse: \CheckIn.session)
    var checkIns: [CheckIn]?
    
    @Relationship(deleteRule: .cascade, inverse: \VolunteerAvailability.session)
    var availabilities: [VolunteerAvailability]?
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        name: String,
        date: Date,
        startTime: Date,
        endTime: Date,
        displayOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.displayOrder = displayOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var timeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    var displayTitle: String {
        "\(name) (\(timeRange))"
    }
}
