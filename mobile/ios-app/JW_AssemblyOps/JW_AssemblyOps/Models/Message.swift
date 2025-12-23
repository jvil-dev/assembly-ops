//
//  Message.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/22/25.
//

import Foundation
import SwiftData

@Model
final class Message {
    // MARK: - Properties
    
    @Attribute(.unique) var id: String
    var content: String
    var priority: MessagePriority
    var recipientType: RecipientType
    
    // For targeted messages
    var targetAssignmentId: String?
    var targetRoleId: String?
    
    // Quick alert (predefined message)
    var isQuickAlert: Bool
    var quickAlertType: String?
    
    // Timestamps
    var sentAt: Date
    var createdAt: Date
    var updatedAt: Date
    var lastSyncedAt: Date?
    
    // MARK: - Relationships
    
    var event: Event?
    var sender: Overseer?
    
    @Relationship(deleteRule: .cascade, inverse: \MessageRecipient.message)
    var recipients: [MessageRecipient]?
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        content: String,
        priority: MessagePriority = .normal,
        recipientType: RecipientType = .all,
        targetAssignmentId: String? = nil,
        targetRoleId: String? = nil,
        isQuickAlert: Bool = false,
        quickAlertType: String? = nil,
        sentAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.priority = priority
        self.recipientType = recipientType
        self.targetAssignmentId = targetAssignmentId
        self.targetRoleId = targetRoleId
        self.isQuickAlert = isQuickAlert
        self.quickAlertType = quickAlertType
        self.sentAt = sentAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var isUrgent: Bool {
        priority == .urgent || priority == .emergency
    }
    
    var recipientCount: Int {
        recipients?.count ?? 0
    }
    
    var readCount: Int {
        recipients?.filter { $0.isRead }.count ?? 0
    }
}
