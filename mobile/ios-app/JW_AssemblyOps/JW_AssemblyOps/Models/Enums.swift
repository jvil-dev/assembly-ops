//
//  Enums.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/22/25.
//

import Foundation

// MARK: - Event types

enum EventType: String, Codable, CaseIterable {
    case circuitAssembly = "CIRCUIT_ASSEMBLY"
    case regionalConvention = "REGIONAL_CONVENTION"
    
    var displayName: String {
        switch self {
        case .circuitAssembly:
            return "Circuit Assembly"
        case .regionalConvention:
            return "Regional Convention"
        }
    }
}

// MARK: - Overseer Types

enum OverseerType: String, Codable, CaseIterable {
    case eventOverseer = "EVENT_OVERSEER"
    case departmentOverseer = "DEPARTMENT_OVERSEER"
    
    var displayName: String {
        switch self {
        case .eventOverseer:
            return "Event Overseer"
        case .departmentOverseer:
            return "Department Overseer"
        }
    }
}

// MARK: - Department Types

enum DepartmentType: String, Codable, CaseIterable {
    // Both event types
    case accounts = "ACCOUNTS"
    case attendant = "ATTENDANT"
    case audioVideo = "AUDIO_VIDEO"
    case baptism = "BAPTISM"
    case cleaning = "CLEANING"
    case firstAid = "FIRST_AID"
    case informationVolunteerService = "INFORMATION_VOLUNTEER_SERVICE"
    case installation = "INSTALLATION"
    case lostAndFoundCheckroom = "LOST_AND_FOUND_CHECKROOM"
    case parking = "PARKING"
    case rooming = "ROOMING"
    
    // Regional Convention only
    case truckingEquipment = "TRUCKING_EQUIPMENT"
    
    var displayName: String {
        switch self {
        case .accounts:
            return "Accounts"
        case .attendant:
            return "Attendant"
        case .audioVideo:
            return "Audio/Video"
        case .baptism:
            return "Baptism"
        case .cleaning:
            return "Cleaning"
        case .firstAid:
            return "First Aid"
        case .informationVolunteerService:
            return "Information & Volunteer Service"
        case .installation:
            return "Installation"
        case .lostAndFoundCheckroom:
            return "Lost & Found Checkroom"
        case .parking:
            return "Parking"
        case .rooming:
            return "Rooming"
        case .truckingEquipment:
            return "Trucking Equipment"
        }
    }
    
    /// Returns true if this department is available for the given event type
    func isAvailable(for eventType: EventType) -> Bool {
        switch self {
        case .informationVolunteerService, .truckingEquipment:
            return eventType == .regionalConvention
        default:
            return true
        }
    }
    
    /// Returns all departments available for a given event type
    static func departments(for eventType: EventType) -> [DepartmentType] {
        return DepartmentType.allCases.filter{ $0.isAvailable(for: eventType) }
    }
}

// MARK: - Appointment Types

enum Appointment: String, Codable, CaseIterable {
    case elder = "ELDER"
    case ministerialServant = "MINISTERIAL_SERVANT"
    case publisher = "PUBLISHER"
    
    var displayName: String {
        switch self {
        case .elder:
            return "Elder"
        case .ministerialServant:
            return "Ministerial Servant"
        case .publisher:
            return "Publisher"
        }
    }
}

// MARK: - Check-in Status

enum CheckInStatus: String, Codable, CaseIterable {
    case checkedIn = "CHECKED_IN"
    case checkedOut = "CHECKED_OUT"
    case missedCheckIn = "MISSED_CHECK_IN"
    case missedCheckOut = "MISSED_CHECK_OUT"
    
    var displayName: String {
        switch self {
        case .checkedIn:
            return "Checked In"
        case .checkedOut:
            return "Checked Out"
        case .missedCheckIn:
            return "Missed Check In"
        case .missedCheckOut:
            return "Missed Check Out"
        }
    }
}

// MARK: - Message Priority

enum MessagePriority: String, Codable, CaseIterable {
    case normal = "NORMAL"
    case urgent = "URGENT"
    case emergency = "EMERGENCY"
    
    var displayName: String {
        switch self {
        case .normal:
            return "Normal"
        case .urgent:
            return "Urgent"
        case .emergency:
            return "Emergency"
        }
    }
}

// MARK: - Recipient Type

enum RecipientType: String, Codable, CaseIterable {
    case individual = "INDIVIDUAL"
    case assignment = "ASSIGNMENT"
    case role = "ROLE"
    case all = "ALL"
    
    var displayName: String {
        switch self {
        case .individual:
            return "Individual"
        case .assignment:
            return "Assignment"
        case .role:
            return "Role"
        case .all:
            return "All Volunteers"
        }
    }
}

// MARK: - Event Request Status

enum EventRequestStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        }
    }
}

// MARK: - Offline Action Type

enum OfflineActionType: String, Codable, CaseIterable {
    case checkIn = "CHECK_IN"
    case checkOut = "CHECK_OUT"
    case createVolunteer = "CREATE_VOLUNTEER"
    case updateVolunteer = "UPDATE_VOLUNTEER"
    case createAssignment = "CREATE_ASSIGNMENT"
    case updateAssignment = "UPDATE_ASSIGNMENT"
    case sendMessage = "SEND_MESSAGE"
    case markMessageRead = "MARK_MESSAGE_READ"
    case updateAvailability = "UPDATE_AVAILABILITY"
}

// MARK: - Offline Action Status

enum OfflineActionStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case syncing = "SYNCING"
    case completed = "COMPLETED"
    case failed = "FAILED"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .syncing:
            return "Syncing"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }
}

// MARK: - Language

enum Language: String, Codable, CaseIterable {
    case english = "en"
    case spanish = "es"
    
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .spanish:
            return "Español"
        }
    }
}
