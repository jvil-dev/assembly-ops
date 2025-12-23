//
//  ScheduleAssignment.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/22/25.
//


import Foundation
import SwiftData

/// Links a volunteer to a specific session and assignment
@Model
final class ScheduleAssignment {
    // MARK: - Properties
    
    @Attribute(.unique) var id: String
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    var lastSyncedAt: Date?
    
    // MARK: - Relationships
    
    var volunteer: Volunteer?
    var session: Session?
    var assignment: Assignment?
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}