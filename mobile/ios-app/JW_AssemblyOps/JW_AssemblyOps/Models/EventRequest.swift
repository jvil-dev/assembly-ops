//
//  EventRequest.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/22/25.
//

import Foundation
import SwiftData

/// Overseer request for an event not in the preloaded list
@Model
final class EventRequest {
    // MARK: - Properties
    
    @Attribute(.unique) var id: String
    var eventType: EventType
    var circuit: String?
    var date: Date
    var endDate: Date?
    var theme: String
    var scripture: String
    var venueName: String
    var streetAddress: String
    var city: String
    var state: String
    var zip: String
    var language: Language
    
    // Request tracking
    var status: EventRequestStatus
    var requestedById: String
    var requestedByEmail: String
    var requestedByName: String
    var adminNotes: String?
    var rejectionReason: String?
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    var reviewedAt: Date?
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
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
        status: EventRequestStatus = .pending,
        requestedById: String,
        requestedByEmail: String,
        requestedByName: String,
        adminNotes: String? = nil,
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
        self.status = status
        self.requestedById = requestedById
        self.requestedByEmail = requestedByEmail
        self.requestedByName = requestedByName
        self.adminNotes = adminNotes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
            
    // MARK: - Computed Properties
            
    var isPending: Bool {
        status == .pending
    }
    
    var fullAddress: String {
        "\(streetAddress), \(city), \(state) \(zip)"
    }
}
