//
//  Role.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/22/25.
//


import Foundation
import SwiftData

@Model
final class Role {
    // MARK: - Properties
    
    @Attribute(.unique) var id: String
    var name: String
    var displayOrder: Int
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    var lastSyncedAt: Date?
    
    // MARK: - Relationships
    
    var event: Event?
    
    @Relationship(deleteRule: .nullify, inverse: \Volunteer.role)
    var volunteers: [Volunteer]?
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        name: String,
        displayOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.displayOrder = displayOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}