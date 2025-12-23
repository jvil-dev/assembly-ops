//
//  VolunteerAvailability.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/22/25.
//

import Foundation
import SwiftData

@Model
final class VolunteerAvailability {
    // MARK: - Properties
    
    @Attribute(.unique) var id: String
    var isAvailable: Bool
    var notes: String?
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    var lastSyncedAt: Date?
    
    // MARK: - Relationships
    
    var volunteer: Volunteer?
    var session: Session?
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        isAvailable: Bool = true,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.isAvailable = isAvailable
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
