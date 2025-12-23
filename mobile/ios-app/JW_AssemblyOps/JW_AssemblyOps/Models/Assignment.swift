//
//  Assignment.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/22/25.
//


import Foundation
import SwiftData

/// Physical post/location where volunteers are assigned (renamed from Zone)
@Model
final class Assignment {
    // MARK: - Properties
    
    @Attribute(.unique) var id: String
    var name: String  // e.g., "East Lobby", "Lot A Entrance", "Camera 1"
    var capacity: Int  // Number of volunteers needed
    var description_: String?  // Using underscore to avoid Swift keyword
    var displayOrder: Int
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    var lastSyncedAt: Date?
    
    // MARK: - Relationships
    
    var event: Event?
    var department: Department?
    
    @Relationship(deleteRule: .cascade, inverse: \ScheduleAssignment.assignment)
    var scheduleAssignments: [ScheduleAssignment]?
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        name: String,
        capacity: Int = 1,
        description_: String? = nil,
        displayOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.capacity = capacity
        self.description_ = description_
        self.displayOrder = displayOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var assignedCount: Int {
        scheduleAssignments?.count ?? 0
    }
    
    var isFull: Bool {
        assignedCount >= capacity
    }
    
    var availableSlots: Int {
        max(0, capacity - assignedCount)
    }
}
