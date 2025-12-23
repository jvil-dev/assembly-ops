//
//  AttendanceCount.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/22/25.
//


import Foundation
import SwiftData

/// Audience attendance count per section - matches CO-24 form
@Model
final class AttendanceCount {
    // MARK: - Properties
    
    @Attribute(.unique) var id: String
    var count: Int  // Attendance (total count for section)
    var countTime: Date  // Count Time (when count was taken)
    var notes: String?
    
    // Timestamps
    var submittedAt: Date
    var createdAt: Date
    var updatedAt: Date
    var lastSyncedAt: Date?
    
    // MARK: - Relationships
    
    var session: Session?  // Which session (Day 1 AM, Day 1 PM, etc.)
    var assignment: Assignment?  // Which section (Sección)
    var submittedBy: Volunteer?  // Attendant who counted
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        count: Int,
        countTime: Date = Date(),
        notes: String? = nil,
        submittedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.count = count
        self.countTime = countTime
        self.notes = notes
        self.submittedAt = submittedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
