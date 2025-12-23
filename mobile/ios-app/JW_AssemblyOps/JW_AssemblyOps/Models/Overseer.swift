//
//  Overseer.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/22/25.
//

import Foundation
import SwiftData

@Model
final class Overseer {
    // MARK: - Properties
    
    @Attribute(.unique) var id: String
    var email: String
    var name: String
    var overseerType: OverseerType
    var departmentId: String?
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    
    // Sync tracking
    var lastSyncedAt: Date?
    
    // MARK: - Relationships
    
    @Relationship(deleteRule: .nullify, inverse: \Event.createdBy)
    var createdEvents: [Event]?
    
    @Relationship(deleteRule: .nullify, inverse: \Message.sender)
    var sentMessages: [Message]?
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        email: String,
        name: String,
        overseerType: OverseerType = .departmentOverseer,
        departmentId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.overseerType = overseerType
        self.departmentId = departmentId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    var isEventOverseet: Bool {
        overseerType == .eventOverseer
    }
    
    var isDepartmentOverseer: Bool {
        overseerType == .departmentOverseer
    }
}
