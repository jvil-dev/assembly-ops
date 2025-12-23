//
//  MessageRecipient.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/22/25.
//

import Foundation
import SwiftData

@Model
final class MessageRecipient {
    // MARK: - Properties
    
    @Attribute(.unique) var id: String
    var isRead: Bool
    var readAt: Date?
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    var lastSyncedAt: Date?
    
    // MARK: - Relationships
    
    var message: Message?
    var volunteer: Volunteer?
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        isRead: Bool = false,
        readAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.isRead = isRead
        self.readAt = readAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Methods
    
    func markAsRead() {
        isRead = true
        readAt = Date()
        updatedAt = Date()
    }
}
