//
//  CheckIn.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/22/25.
//


import Foundation
import SwiftData

@Model
final class CheckIn {
    // MARK: - Properties
    
    @Attribute(.unique) var id: String
    var status: CheckInStatus
    var checkInTime: Date?
    var checkOutTime: Date?
    var notes: String?
    
    // Overseer override tracking
    var wasOverseerOverride: Bool
    var overrideOverseerId: String?
    var overrideReason: String?
    
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
        status: CheckInStatus = .checkedIn,
        checkInTime: Date? = nil,
        checkOutTime: Date? = nil,
        notes: String? = nil,
        wasOverseerOverride: Bool = false,
        overrideOverseerId: String? = nil,
        overrideReason: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.status = status
        self.checkInTime = checkInTime
        self.checkOutTime = checkOutTime
        self.notes = notes
        self.wasOverseerOverride = wasOverseerOverride
        self.overrideOverseerId = overrideOverseerId
        self.overrideReason = overrideReason
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var isCheckedIn: Bool {
        status == .checkedIn
    }
    
    var isCheckedOut: Bool {
        status == .checkedOut
    }
    
    var duration: TimeInterval? {
        guard let checkIn = checkInTime, let checkOut = checkOutTime else {
            return nil
        }
        return checkOut.timeIntervalSince(checkIn)
    }
    
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}