//
//  EventTemplate.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/22/25.
//

import Foundation
import SwiftData

/// Preloaded events from CSV that admins can claim
@Model
final class EventTemplate {
    // MARK: - Properties
    
    @Attribute(.unique) var id: String  // e.g., "evt_ma1_2025-12-20_en"
    var eventType: EventType
    var circuit: String?  // Only for circuit assemblies (e.g., "MA-1")
    var date: Date
    var endDate: Date?  // Only for multi-day regionals
    var theme: String
    var scripture: String
    var venueName: String
    var streetAddress: String
    var city: String
    var state: String
    var zip: String
    var language: Language
    
    // Status
    var isClaimed: Bool
    var claimedEventId: String?  // Reference to created Event
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initializer
    
    init(
        id: String,
        eventType: EventType,
        circuit: String? = nil,
        date: Date,
        endDate: Date? = nil,
        theme: String,
        scripture: String,
        venueName: String,
        streetAddress: String,
        city: String,
        state: String,
        zip: String,
        language: Language = .english,
        isClaimed: Bool = false,
        claimedEventId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.eventType = eventType
        self.circuit = circuit
        self.date = date
        self.endDate = endDate
        self.theme = theme
        self.scripture = scripture
        self.venueName = venueName
        self.streetAddress = streetAddress
        self.city = city
        self.state = state
        self.zip = zip
        self.language = language
        self.isClaimed = isClaimed
        self.claimedEventId = claimedEventId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var fullAddress: String {
        "\(streetAddress), \(city), \(state) \(zip)"
    }
    
    var displayTitle: String {
        if let circuit = circuit {
            return "\(circuit) - \(theme)"
        }
        return theme
    }
    
    var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if let endDate = endDate {
            return "\(formatter.string(from: date)) - \(formatter.string(from: endDate))"
        }
        return formatter.string(from: date)
    }
}
