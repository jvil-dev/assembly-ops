//
//  AttendantModels.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/16/26.
//

// MARK: - Attendant Models
//
// Data models for attendant department features.
// Used by AttendantService and attendant ViewModels.
//
// Types:
//   - SafetyIncidentTypeItem: Incident type enum with display names/icons
//   - SafetyIncidentItem: Reported safety hazard
//   - LostPersonAlertItem: Missing person report
//   - AttendantMeetingItem: Pre-event attendant meeting
//   - MeetingAttendeeItem: Attendee within a meeting
//
// Data Flow:
//   1. GraphQL queries return Apollo generated types
//   2. init(from:) mappers convert to these domain models
//   3. ViewModels expose these types to Views
//

import Foundation
import SwiftUI

// MARK: - Safety Incident Type

enum SafetyIncidentTypeItem: String, CaseIterable {
    case buildingDefect = "BUILDING_DEFECT"
    case wetFloor = "WET_FLOOR"
    case unsafeCondition = "UNSAFE_CONDITION"
    case medicalEmergency = "MEDICAL_EMERGENCY"
    case disruptiveIndividual = "DISRUPTIVE_INDIVIDUAL"
    case bombThreat = "BOMB_THREAT"
    case violentIndividual = "VIOLENT_INDIVIDUAL"
    case severeWeather = "SEVERE_WEATHER"
    case activeShooter = "ACTIVE_SHOOTER"
    case other = "OTHER"

    var displayName: String {
        switch self {
        case .buildingDefect: return "attendant.incidents.type.buildingDefect".localized
        case .wetFloor: return "attendant.incidents.type.wetFloor".localized
        case .unsafeCondition: return "attendant.incidents.type.unsafeCondition".localized
        case .medicalEmergency: return "attendant.incidents.type.medicalEmergency".localized
        case .disruptiveIndividual: return "attendant.incidents.type.disruptiveIndividual".localized
        case .bombThreat: return "attendant.incidents.type.bombThreat".localized
        case .violentIndividual: return "attendant.incidents.type.violentIndividual".localized
        case .severeWeather: return "attendant.incidents.type.severeWeather".localized
        case .activeShooter: return "attendant.incidents.type.activeShooter".localized
        case .other: return "attendant.incidents.type.other".localized
        }
    }

    var icon: String {
        switch self {
        case .buildingDefect: return "building.2.crop.circle"
        case .wetFloor: return "drop.triangle"
        case .unsafeCondition: return "exclamationmark.triangle"
        case .medicalEmergency: return "cross.circle"
        case .disruptiveIndividual: return "person.crop.circle.badge.exclamationmark"
        case .bombThreat: return "light.beacon.max"
        case .violentIndividual: return "shield.lefthalf.filled.trianglebadge.exclamationmark"
        case .severeWeather: return "cloud.bolt.rain"
        case .activeShooter: return "figure.run"
        case .other: return "questionmark.circle"
        }
    }
}

// MARK: - Safety Incident

struct SafetyIncidentItem: Identifiable {
    let id: String
    let type: SafetyIncidentTypeItem
    let description: String
    let location: String?
    let postId: String?
    let postName: String?
    let reportedByName: String
    let resolved: Bool
    let resolvedAt: Date?
    let resolvedByName: String?
    let resolutionNotes: String?
    let createdAt: Date
}

extension SafetyIncidentItem {
    init?(from data: AssemblyOpsAPI.SafetyIncidentsQuery.Data.SafetyIncident) {
        guard let incidentType = SafetyIncidentTypeItem(rawValue: data.type.rawValue) else { return nil }
        self.id = data.id
        self.type = incidentType
        self.description = data.description
        self.location = data.location
        self.postId = data.post?.id
        self.postName = data.post?.name
        let profile = data.reportedBy.volunteerProfile
        self.reportedByName = "\(profile.firstName) \(profile.lastName)"
        self.resolved = data.resolved
        self.resolvedAt = data.resolvedAt.flatMap { DateUtils.parseISO8601($0) }
        if let resolver = data.resolvedBy {
            self.resolvedByName = "\(resolver.firstName) \(resolver.lastName)"
        } else {
            self.resolvedByName = nil
        }
        self.resolutionNotes = data.resolutionNotes
        self.createdAt = DateUtils.parseISO8601(data.createdAt) ?? Date()
    }

    init?(fromReport data: AssemblyOpsAPI.ReportSafetyIncidentMutation.Data.ReportSafetyIncident) {
        guard let incidentType = SafetyIncidentTypeItem(rawValue: data.type.rawValue) else { return nil }
        self.id = data.id
        self.type = incidentType
        self.description = data.description
        self.location = data.location
        self.postId = data.post?.id
        self.postName = data.post?.name
        self.reportedByName = ""
        self.resolved = false
        self.resolvedAt = nil
        self.resolvedByName = nil
        self.resolutionNotes = nil
        self.createdAt = DateUtils.parseISO8601(data.createdAt) ?? Date()
    }
}

// MARK: - Lost Person Alert

struct LostPersonAlertItem: Identifiable {
    let id: String
    let personName: String
    let age: Int?
    let description: String
    let lastSeenLocation: String?
    let lastSeenTime: Date?
    let contactName: String
    let contactPhone: String?
    let reportedByName: String
    let resolved: Bool
    let resolvedAt: Date?
    let resolvedByName: String?
    let resolutionNotes: String?
    let createdAt: Date
}

extension LostPersonAlertItem {
    init?(from data: AssemblyOpsAPI.LostPersonAlertsQuery.Data.LostPersonAlert) {
        self.id = data.id
        self.personName = data.personName
        self.age = data.age
        self.description = data.description
        self.lastSeenLocation = data.lastSeenLocation
        self.lastSeenTime = data.lastSeenTime.flatMap { DateUtils.parseISO8601($0) }
        self.contactName = data.contactName
        self.contactPhone = data.contactPhone
        let profile = data.reportedBy.volunteerProfile
        self.reportedByName = "\(profile.firstName) \(profile.lastName)"
        self.resolved = data.resolved
        self.resolvedAt = data.resolvedAt.flatMap { DateUtils.parseISO8601($0) }
        if let resolver = data.resolvedBy {
            self.resolvedByName = "\(resolver.firstName) \(resolver.lastName)"
        } else {
            self.resolvedByName = nil
        }
        self.resolutionNotes = data.resolutionNotes
        self.createdAt = DateUtils.parseISO8601(data.createdAt) ?? Date()
    }

    init?(fromCreate data: AssemblyOpsAPI.CreateLostPersonAlertMutation.Data.CreateLostPersonAlert) {
        self.id = data.id
        self.personName = data.personName
        self.age = data.age
        self.description = data.description
        self.lastSeenLocation = data.lastSeenLocation
        self.lastSeenTime = data.lastSeenTime.flatMap { DateUtils.parseISO8601($0) }
        self.contactName = data.contactName
        self.contactPhone = data.contactPhone
        self.reportedByName = ""
        self.resolved = false
        self.resolvedAt = nil
        self.resolvedByName = nil
        self.resolutionNotes = nil
        self.createdAt = DateUtils.parseISO8601(data.createdAt) ?? Date()
    }
}

// MARK: - Attendant Meeting

struct AttendantMeetingItem: Identifiable {
    let id: String
    let sessionName: String
    let sessionId: String
    let meetingDate: Date
    let notes: String?
    let createdByName: String
    let attendees: [MeetingAttendeeItem]
    let createdAt: Date
}

extension AttendantMeetingItem {
    init?(from data: AssemblyOpsAPI.AttendantMeetingsQuery.Data.AttendantMeeting) {
        self.id = data.id
        self.sessionName = data.session.name
        self.sessionId = data.session.id
        self.meetingDate = DateUtils.parseISO8601(data.meetingDate) ?? Date()
        self.notes = data.notes
        self.createdByName = "\(data.createdBy.firstName) \(data.createdBy.lastName)"
        self.attendees = data.attendees.compactMap { MeetingAttendeeItem(from: $0) }
        self.createdAt = DateUtils.parseISO8601(data.createdAt) ?? Date()
    }

    init?(fromCreate data: AssemblyOpsAPI.CreateAttendantMeetingMutation.Data.CreateAttendantMeeting) {
        self.id = data.id
        self.sessionName = data.session.name
        self.sessionId = data.session.id
        self.meetingDate = DateUtils.parseISO8601(data.meetingDate) ?? Date()
        self.notes = data.notes
        self.createdByName = ""
        self.attendees = data.attendees.compactMap { MeetingAttendeeItem(fromCreate: $0) }
        self.createdAt = DateUtils.parseISO8601(data.createdAt) ?? Date()
    }

    init?(fromMyMeeting data: AssemblyOpsAPI.MyAttendantMeetingsQuery.Data.MyAttendantMeeting) {
        self.id = data.id
        self.sessionName = data.session.name
        self.sessionId = data.session.id
        self.meetingDate = DateUtils.parseISO8601(data.meetingDate) ?? Date()
        self.notes = data.notes
        self.createdByName = "\(data.createdBy.firstName) \(data.createdBy.lastName)"
        self.attendees = data.attendees.compactMap { MeetingAttendeeItem(fromMyMeeting: $0) }
        self.createdAt = DateUtils.parseISO8601(data.createdAt) ?? Date()
    }
}

// MARK: - Meeting Attendee

struct MeetingAttendeeItem: Identifiable {
    let id: String
    let volunteerId: String
    let volunteerName: String
}

extension MeetingAttendeeItem {
    init?(from data: AssemblyOpsAPI.AttendantMeetingsQuery.Data.AttendantMeeting.Attendee) {
        self.id = data.id
        self.volunteerId = data.eventVolunteer.id
        let profile = data.eventVolunteer.volunteerProfile
        self.volunteerName = "\(profile.firstName) \(profile.lastName)"
    }

    init?(fromCreate data: AssemblyOpsAPI.CreateAttendantMeetingMutation.Data.CreateAttendantMeeting.Attendee) {
        self.id = data.id
        self.volunteerId = data.eventVolunteer.id
        let profile = data.eventVolunteer.volunteerProfile
        self.volunteerName = "\(profile.firstName) \(profile.lastName)"
    }

    init?(fromMyMeeting data: AssemblyOpsAPI.MyAttendantMeetingsQuery.Data.MyAttendantMeeting.Attendee) {
        self.id = data.id
        self.volunteerId = data.eventVolunteer.id
        let profile = data.eventVolunteer.volunteerProfile
        self.volunteerName = "\(profile.firstName) \(profile.lastName)"
    }
}

// MARK: - Walk-Through Completion

struct WalkThroughCompletionItem: Identifiable {
    let id: String
    let sessionId: String
    let sessionName: String
    let completedAt: Date
    let itemCount: Int
    let notes: String?
    let volunteerName: String?
}

extension WalkThroughCompletionItem {
    init?(fromMy data: AssemblyOpsAPI.MyWalkThroughCompletionsQuery.Data.MyWalkThroughCompletion) {
        self.id = data.id
        self.sessionId = data.session.id
        self.sessionName = data.session.name
        self.completedAt = DateUtils.parseISO8601(data.completedAt) ?? Date()
        self.itemCount = data.itemCount
        self.notes = data.notes
        self.volunteerName = nil
    }

    init?(fromAdmin data: AssemblyOpsAPI.WalkThroughCompletionsQuery.Data.WalkThroughCompletion) {
        self.id = data.id
        self.sessionId = data.session.id
        self.sessionName = data.session.name
        self.completedAt = DateUtils.parseISO8601(data.completedAt) ?? Date()
        self.itemCount = data.itemCount
        self.notes = data.notes
        let profile = data.eventVolunteer.volunteerProfile
        self.volunteerName = "\(profile.firstName) \(profile.lastName)"
    }
}

// MARK: - Post Session Status

enum SeatingSectionStatusItem: String, CaseIterable {
    case open = "OPEN"
    case filling = "FILLING"
    case full = "FULL"

    var displayName: String {
        switch self {
        case .open: return "attendant.seating.status.open".localized
        case .filling: return "attendant.seating.status.filling".localized
        case .full: return "attendant.seating.status.full".localized
        }
    }

    var icon: String {
        switch self {
        case .open: return "checkmark.circle"
        case .filling: return "circle.lefthalf.filled"
        case .full: return "xmark.circle"
        }
    }

    var color: SwiftUI.Color {
        switch self {
        case .open: return AppTheme.StatusColors.accepted
        case .filling: return AppTheme.StatusColors.pending
        case .full: return AppTheme.StatusColors.declined
        }
    }
}

struct PostSessionStatusItem: Identifiable {
    let id: String
    let postId: String
    let postName: String
    let postLocation: String?
    let postCategory: String?
    let sessionId: String
    let sessionName: String
    var status: SeatingSectionStatusItem
    let updatedAt: Date
}

extension PostSessionStatusItem {
    init?(from data: AssemblyOpsAPI.PostSessionStatusesQuery.Data.PostSessionStatus) {
        guard let statusItem = SeatingSectionStatusItem(rawValue: data.status.rawValue) else { return nil }
        self.id = data.id
        self.postId = data.post.id
        self.postName = data.post.name
        self.postLocation = data.post.location
        self.postCategory = data.post.category
        self.sessionId = data.session.id
        self.sessionName = data.session.name
        self.status = statusItem
        self.updatedAt = DateUtils.parseISO8601(data.updatedAt) ?? Date()
    }
}

// MARK: - Facility Location

struct FacilityLocationItem: Identifiable {
    let id: String
    let name: String
    let location: String
    let description: String?
    let sortOrder: Int
}

extension FacilityLocationItem {
    init(from data: AssemblyOpsAPI.FacilityLocationsQuery.Data.FacilityLocation) {
        self.id = data.id
        self.name = data.name
        self.location = data.location
        self.description = data.description
        self.sortOrder = data.sortOrder
    }

    init(fromCreate data: AssemblyOpsAPI.CreateFacilityLocationMutation.Data.CreateFacilityLocation) {
        self.id = data.id
        self.name = data.name
        self.location = data.location
        self.description = data.description
        self.sortOrder = data.sortOrder
    }
}

// MARK: - Concern Item (unified feed for volunteer view)

enum ConcernItem: Identifiable {
    case incident(SafetyIncidentItem)
    case alert(LostPersonAlertItem)

    var id: String {
        switch self {
        case .incident(let i): return "i-\(i.id)"
        case .alert(let a): return "a-\(a.id)"
        }
    }

    var createdAt: Date {
        switch self {
        case .incident(let i): return i.createdAt
        case .alert(let a): return a.createdAt
        }
    }

    var isResolved: Bool {
        switch self {
        case .incident(let i): return i.resolved
        case .alert(let a): return a.resolved
        }
    }
}
