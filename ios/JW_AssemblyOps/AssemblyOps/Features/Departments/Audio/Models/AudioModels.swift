//
//  AudioModels.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Audio Models
//
// Domain models for Audio department features.
// Used by AudioVideoService and Audio ViewModels.
//
// Types:
//   - AudioEquipmentCategoryItem: Equipment category enum with display names/icons
//   - AudioEquipmentConditionItem: Condition enum (Good/Needs Repair/Out of Service)
//   - AudioDamageSeverityItem: Severity enum (Minor/Moderate/Severe)
//   - AudioHazardTypeItem: 10 hazard types with icons
//   - AudioEquipmentItemModel: Equipment inventory item
//   - AudioEquipmentCheckoutItem: Chain-of-custody record
//   - AudioDamageReportItem: Damage report with resolution flow
//   - AudioHazardAssessmentItem: Job hazard analysis
//   - AudioSafetyBriefingItem: Safety briefing with attendees
//   - AudioEquipmentSummaryItem: Dashboard aggregate stats

import Foundation
import SwiftUI

// MARK: - Equipment Category

enum AudioEquipmentCategoryItem: String, CaseIterable {
    case cameraPtz = "CAMERA_PTZ"
    case cameraManned = "CAMERA_MANNED"
    case tripod = "TRIPOD"
    case audioMixer = "AUDIO_MIXER"
    case videoSwitcher = "VIDEO_SWITCHER"
    case mediaPlayer = "MEDIA_PLAYER"
    case ledPanel = "LED_PANEL"
    case loudspeaker = "LOUDSPEAKER"
    case microphone = "MICROPHONE"
    case stageMonitor = "STAGE_MONITOR"
    case intercom = "INTERCOM"
    case cable = "CABLE"
    case stageLighting = "STAGE_LIGHTING"
    case recordingDevice = "RECORDING_DEVICE"
    case assistiveListening = "ASSISTIVE_LISTENING"
    case accessory = "ACCESSORY"

    var displayName: String {
        switch self {
        case .cameraPtz: return "av.equipment.category.cameraPtz".localized
        case .cameraManned: return "av.equipment.category.cameraManned".localized
        case .tripod: return "av.equipment.category.tripod".localized
        case .audioMixer: return "av.equipment.category.audioMixer".localized
        case .videoSwitcher: return "av.equipment.category.videoSwitcher".localized
        case .mediaPlayer: return "av.equipment.category.mediaPlayer".localized
        case .ledPanel: return "av.equipment.category.ledPanel".localized
        case .loudspeaker: return "av.equipment.category.loudspeaker".localized
        case .microphone: return "av.equipment.category.microphone".localized
        case .stageMonitor: return "av.equipment.category.stageMonitor".localized
        case .intercom: return "av.equipment.category.intercom".localized
        case .cable: return "av.equipment.category.cable".localized
        case .stageLighting: return "av.equipment.category.stageLighting".localized
        case .recordingDevice: return "av.equipment.category.recordingDevice".localized
        case .assistiveListening: return "av.equipment.category.assistiveListening".localized
        case .accessory: return "av.equipment.category.accessory".localized
        }
    }

    /// Categories relevant to the Audio crew (CO-160 Ch. 2)
    static let audioRelevantCategories: Set<AudioEquipmentCategoryItem> = [
        .audioMixer, .loudspeaker, .microphone, .stageMonitor,
        .intercom, .cable, .assistiveListening, .accessory
    ]

    /// Categories relevant to the Video crew (CO-160 Ch. 4)
    static let videoRelevantCategories: Set<AudioEquipmentCategoryItem> = [
        .cameraPtz, .cameraManned, .tripod, .videoSwitcher,
        .mediaPlayer, .ledPanel, .stageLighting, .intercom,
        .cable, .recordingDevice, .accessory
    ]

    var icon: String {
        switch self {
        case .cameraPtz: return "web.camera"
        case .cameraManned: return "video.circle"
        case .tripod: return "camera.on.rectangle"
        case .audioMixer: return "slider.horizontal.3"
        case .videoSwitcher: return "rectangle.3.group"
        case .mediaPlayer: return "play.rectangle"
        case .ledPanel: return "tv"
        case .loudspeaker: return "speaker.wave.3"
        case .microphone: return "mic"
        case .stageMonitor: return "speaker"
        case .intercom: return "headphones"
        case .cable: return "cable.connector"
        case .stageLighting: return "light.recessed"
        case .recordingDevice: return "record.circle"
        case .assistiveListening: return "ear"
        case .accessory: return "wrench.and.screwdriver"
        }
    }
}

// MARK: - Equipment Condition

enum AudioEquipmentConditionItem: String, CaseIterable {
    case good = "GOOD"
    case needsRepair = "NEEDS_REPAIR"
    case outOfService = "OUT_OF_SERVICE"

    var displayName: String {
        switch self {
        case .good: return "av.equipment.condition.good".localized
        case .needsRepair: return "av.equipment.condition.needsRepair".localized
        case .outOfService: return "av.equipment.condition.outOfService".localized
        }
    }

    var color: SwiftUI.Color {
        switch self {
        case .good: return AppTheme.StatusColors.accepted
        case .needsRepair: return AppTheme.StatusColors.pending
        case .outOfService: return AppTheme.StatusColors.declined
        }
    }

    var icon: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .needsRepair: return "wrench.and.screwdriver.fill"
        case .outOfService: return "xmark.circle.fill"
        }
    }
}

// MARK: - Damage Severity

enum AudioDamageSeverityItem: String, CaseIterable {
    case minor = "MINOR"
    case moderate = "MODERATE"
    case severe = "SEVERE"

    var displayName: String {
        switch self {
        case .minor: return "av.damage.severity.minor".localized
        case .moderate: return "av.damage.severity.moderate".localized
        case .severe: return "av.damage.severity.severe".localized
        }
    }

    var color: SwiftUI.Color {
        switch self {
        case .minor: return AppTheme.StatusColors.pending
        case .moderate: return .orange
        case .severe: return AppTheme.StatusColors.declined
        }
    }

    var icon: String {
        switch self {
        case .minor: return "exclamationmark.triangle"
        case .moderate: return "exclamationmark.triangle.fill"
        case .severe: return "xmark.octagon.fill"
        }
    }
}

// MARK: - Hazard Type

enum AudioHazardTypeItem: String, CaseIterable {
    case workingAtHeight = "WORKING_AT_HEIGHT"
    case electricalExposure = "ELECTRICAL_EXPOSURE"
    case elevatedPlatform = "ELEVATED_PLATFORM"
    case powerTools = "POWER_TOOLS"
    case movingEquipment = "MOVING_EQUIPMENT"
    case nearStairs = "NEAR_STAIRS"
    case unevenSurface = "UNEVEN_SURFACE"
    case heavyLifting = "HEAVY_LIFTING"
    case pinchCrushCut = "PINCH_CRUSH_CUT"
    case extremeConditions = "EXTREME_CONDITIONS"

    var displayName: String {
        switch self {
        case .workingAtHeight: return "av.hazard.type.workingAtHeight".localized
        case .electricalExposure: return "av.hazard.type.electricalExposure".localized
        case .elevatedPlatform: return "av.hazard.type.elevatedPlatform".localized
        case .powerTools: return "av.hazard.type.powerTools".localized
        case .movingEquipment: return "av.hazard.type.movingEquipment".localized
        case .nearStairs: return "av.hazard.type.nearStairs".localized
        case .unevenSurface: return "av.hazard.type.unevenSurface".localized
        case .heavyLifting: return "av.hazard.type.heavyLifting".localized
        case .pinchCrushCut: return "av.hazard.type.pinchCrushCut".localized
        case .extremeConditions: return "av.hazard.type.extremeConditions".localized
        }
    }

    var icon: String {
        switch self {
        case .workingAtHeight: return "arrow.up.to.line"
        case .electricalExposure: return "bolt.trianglebadge.exclamationmark"
        case .elevatedPlatform: return "square.stack.3d.up"
        case .powerTools: return "wrench.and.screwdriver"
        case .movingEquipment: return "shippingbox"
        case .nearStairs: return "stairs"
        case .unevenSurface: return "mountain.2"
        case .heavyLifting: return "figure.strengthtraining.traditional"
        case .pinchCrushCut: return "hand.raised.slash"
        case .extremeConditions: return "thermometer.sun"
        }
    }
}

// MARK: - PPE Types

enum AudioPPEType: String, CaseIterable {
    case hardHat = "HARD_HAT"
    case safetyGlasses = "SAFETY_GLASSES"
    case highVisVest = "HIGH_VIS_VEST"
    case gloves = "GLOVES"
    case workShoes = "WORK_SHOES"
    case fallProtection = "FALL_PROTECTION"
    case hearingProtection = "HEARING_PROTECTION"

    var displayName: String {
        switch self {
        case .hardHat: return "av.ppe.hardHat".localized
        case .safetyGlasses: return "av.ppe.safetyGlasses".localized
        case .highVisVest: return "av.ppe.highVisVest".localized
        case .gloves: return "av.ppe.gloves".localized
        case .workShoes: return "av.ppe.workShoes".localized
        case .fallProtection: return "av.ppe.fallProtection".localized
        case .hearingProtection: return "av.ppe.hearingProtection".localized
        }
    }

    var icon: String {
        switch self {
        case .hardHat: return "helmet.fill"
        case .safetyGlasses: return "eyeglasses"
        case .highVisVest: return "tshirt"
        case .gloves: return "hand.raised"
        case .workShoes: return "shoe"
        case .fallProtection: return "figure.fall"
        case .hearingProtection: return "ear.trianglebadge.exclamationmark"
        }
    }
}

// MARK: - Equipment Item

struct AudioEquipmentItemModel: Identifiable {
    let id: String
    let name: String
    let model: String?
    let serialNumber: String?
    let category: AudioEquipmentCategoryItem
    let condition: AudioEquipmentConditionItem
    let location: String?
    let notes: String?
    let areaId: String?
    let areaName: String?
    let currentCheckout: AudioEquipmentCheckoutItem?
    let createdAt: Date
    let updatedAt: Date
}

extension AudioEquipmentItemModel {
    // From AVEquipmentQuery (includes currentCheckout)
    init?(from data: AssemblyOpsAPI.AVEquipmentQuery.Data.AvEquipment) {
        guard let createdAt = DateUtils.parseISO8601(data.createdAt),
              let updatedAt = DateUtils.parseISO8601(data.updatedAt) else { return nil }
        self.id = data.id
        self.name = data.name
        self.model = data.model
        self.serialNumber = data.serialNumber
        self.category = AudioEquipmentCategoryItem(rawValue: data.category.rawValue) ?? .accessory
        self.condition = AudioEquipmentConditionItem(rawValue: data.condition.rawValue) ?? .good
        self.location = data.location
        self.notes = data.notes
        self.areaId = data.area?.id
        self.areaName = data.area?.name
        self.currentCheckout = data.currentCheckout.flatMap { checkout in
            let user = checkout.checkedOutBy.user
            return AudioEquipmentCheckoutItem(
                id: checkout.id,
                equipmentId: data.id,
                equipmentName: data.name,
                equipmentCategory: AudioEquipmentCategoryItem(rawValue: data.category.rawValue),
                checkedOutByName: "\(user.firstName) \(user.lastName)",
                checkedOutById: checkout.checkedOutBy.id,
                checkedOutAt: DateUtils.parseISO8601(checkout.checkedOutAt) ?? Date(),
                checkedInAt: nil,
                sessionName: checkout.session?.name,
                notes: checkout.notes
            )
        }
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // From CreateAVEquipmentMutation (no currentCheckout, no updatedAt)
    init?(fromCreate data: AssemblyOpsAPI.CreateAVEquipmentMutation.Data.CreateAVEquipment) {
        guard let createdAt = DateUtils.parseISO8601(data.createdAt) else { return nil }
        self.id = data.id
        self.name = data.name
        self.model = data.model
        self.serialNumber = data.serialNumber
        self.category = AudioEquipmentCategoryItem(rawValue: data.category.rawValue) ?? .accessory
        self.condition = AudioEquipmentConditionItem(rawValue: data.condition.rawValue) ?? .good
        self.location = data.location
        self.notes = data.notes
        self.areaId = data.area?.id
        self.areaName = data.area?.name
        self.currentCheckout = nil
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    // From BulkCreateAVEquipmentMutation (minimal fields returned)
    init?(fromBulk data: AssemblyOpsAPI.BulkCreateAVEquipmentMutation.Data.BulkCreateAVEquipment) {
        guard let createdAt = DateUtils.parseISO8601(data.createdAt) else { return nil }
        self.id = data.id
        self.name = data.name
        self.model = nil
        self.serialNumber = nil
        self.category = AudioEquipmentCategoryItem(rawValue: data.category.rawValue) ?? .accessory
        self.condition = AudioEquipmentConditionItem(rawValue: data.condition.rawValue) ?? .good
        self.location = data.location
        self.notes = nil
        self.areaId = data.area?.id
        self.areaName = data.area?.name
        self.currentCheckout = nil
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    // From UpdateAVEquipmentMutation (no currentCheckout, no createdAt)
    init?(fromUpdate data: AssemblyOpsAPI.UpdateAVEquipmentMutation.Data.UpdateAVEquipment) {
        guard let updatedAt = DateUtils.parseISO8601(data.updatedAt) else { return nil }
        self.id = data.id
        self.name = data.name
        self.model = data.model
        self.serialNumber = data.serialNumber
        self.category = AudioEquipmentCategoryItem(rawValue: data.category.rawValue) ?? .accessory
        self.condition = AudioEquipmentConditionItem(rawValue: data.condition.rawValue) ?? .good
        self.location = data.location
        self.notes = data.notes
        self.areaId = data.area?.id
        self.areaName = data.area?.name
        self.currentCheckout = nil
        self.createdAt = updatedAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Equipment Checkout

struct AudioEquipmentCheckoutItem: Identifiable {
    let id: String
    let equipmentId: String?
    let equipmentName: String?
    let equipmentCategory: AudioEquipmentCategoryItem?
    let checkedOutByName: String
    let checkedOutById: String
    let checkedOutAt: Date
    let checkedInAt: Date?
    let sessionName: String?
    let notes: String?
}

extension AudioEquipmentCheckoutItem {
    // From AVEquipmentCheckoutsQuery
    init(fromList data: AssemblyOpsAPI.AVEquipmentCheckoutsQuery.Data.AvEquipmentCheckout) {
        let user = data.checkedOutBy.user
        self.id = data.id
        self.equipmentId = data.equipment.id
        self.equipmentName = data.equipment.name
        self.equipmentCategory = AudioEquipmentCategoryItem(rawValue: data.equipment.category.rawValue)
        self.checkedOutByName = "\(user.firstName) \(user.lastName)"
        self.checkedOutById = data.checkedOutBy.id
        self.checkedOutAt = DateUtils.parseISO8601(data.checkedOutAt) ?? Date()
        self.checkedInAt = data.checkedInAt.flatMap { DateUtils.parseISO8601($0) }
        self.sessionName = data.session?.name
        self.notes = data.notes
    }

    // From CheckoutEquipmentMutation (no checkedInAt — just checked out)
    init(fromCheckout data: AssemblyOpsAPI.CheckoutEquipmentMutation.Data.CheckoutEquipment) {
        let user = data.checkedOutBy.user
        self.id = data.id
        self.equipmentId = data.equipment.id
        self.equipmentName = data.equipment.name
        self.equipmentCategory = AudioEquipmentCategoryItem(rawValue: data.equipment.category.rawValue)
        self.checkedOutByName = "\(user.firstName) \(user.lastName)"
        self.checkedOutById = data.checkedOutBy.id
        self.checkedOutAt = DateUtils.parseISO8601(data.checkedOutAt) ?? Date()
        self.checkedInAt = nil
        self.sessionName = data.session?.name
        self.notes = data.notes
    }
}

// MARK: - Damage Report

struct AudioDamageReportItem: Identifiable {
    let id: String
    let equipmentId: String
    let equipmentName: String
    let equipmentCategory: AudioEquipmentCategoryItem?
    let description: String
    let severity: AudioDamageSeverityItem
    let reportedByName: String
    let sessionName: String?
    let resolved: Bool
    let resolvedAt: Date?
    let resolvedByName: String?
    let resolutionNotes: String?
    let createdAt: Date
}

extension AudioDamageReportItem {
    // From AVDamageReportsQuery
    init?(from data: AssemblyOpsAPI.AVDamageReportsQuery.Data.AvDamageReport) {
        guard let createdAt = DateUtils.parseISO8601(data.createdAt) else { return nil }
        let user = data.reportedBy.user
        self.id = data.id
        self.equipmentId = data.equipment.id
        self.equipmentName = data.equipment.name
        self.equipmentCategory = AudioEquipmentCategoryItem(rawValue: data.equipment.category.rawValue)
        self.description = data.description
        self.severity = AudioDamageSeverityItem(rawValue: data.severity.rawValue) ?? .minor
        self.reportedByName = "\(user.firstName) \(user.lastName)"
        self.sessionName = data.session?.name
        self.resolved = data.resolved
        self.resolvedAt = data.resolvedAt.flatMap { DateUtils.parseISO8601($0) }
        self.resolvedByName = data.resolvedBy.map { "\($0.firstName) \($0.lastName)" }
        self.resolutionNotes = data.resolutionNotes
        self.createdAt = createdAt
    }

    // From ReportAVDamageMutation (no resolvedAt/resolvedBy/resolutionNotes)
    init?(fromReport data: AssemblyOpsAPI.ReportAVDamageMutation.Data.ReportAVDamage) {
        guard let createdAt = DateUtils.parseISO8601(data.createdAt) else { return nil }
        let user = data.reportedBy.user
        self.id = data.id
        self.equipmentId = data.equipment.id
        self.equipmentName = data.equipment.name
        self.equipmentCategory = AudioEquipmentCategoryItem(rawValue: data.equipment.category.rawValue)
        self.description = data.description
        self.severity = AudioDamageSeverityItem(rawValue: data.severity.rawValue) ?? .minor
        self.reportedByName = "\(user.firstName) \(user.lastName)"
        self.sessionName = data.session?.name
        self.resolved = false
        self.resolvedAt = nil
        self.resolvedByName = nil
        self.resolutionNotes = nil
        self.createdAt = createdAt
    }
}

// MARK: - Hazard Assessment

struct AudioHazardAssessmentItem: Identifiable {
    let id: String
    let title: String
    let hazardType: AudioHazardTypeItem
    let description: String
    let controls: String
    let ppeRequired: [String]
    let completedByName: String
    let sessionName: String?
    let completedAt: Date
}

extension AudioHazardAssessmentItem {
    // From AVHazardAssessmentsQuery
    init?(from data: AssemblyOpsAPI.AVHazardAssessmentsQuery.Data.AvHazardAssessment) {
        guard let completedAt = DateUtils.parseISO8601(data.completedAt) else { return nil }
        self.id = data.id
        self.title = data.title
        self.hazardType = AudioHazardTypeItem(rawValue: data.hazardType.rawValue) ?? .electricalExposure
        self.description = data.description
        self.controls = data.controls
        self.ppeRequired = data.ppeRequired
        self.completedByName = "\(data.completedBy.firstName) \(data.completedBy.lastName)"
        self.sessionName = data.session?.name
        self.completedAt = completedAt
    }

    // From CreateAVHazardAssessmentMutation
    init?(fromCreate data: AssemblyOpsAPI.CreateAVHazardAssessmentMutation.Data.CreateAVHazardAssessment) {
        guard let completedAt = DateUtils.parseISO8601(data.completedAt) else { return nil }
        self.id = data.id
        self.title = data.title
        self.hazardType = AudioHazardTypeItem(rawValue: data.hazardType.rawValue) ?? .electricalExposure
        self.description = data.description
        self.controls = data.controls
        self.ppeRequired = data.ppeRequired
        self.completedByName = "\(data.completedBy.firstName) \(data.completedBy.lastName)"
        self.sessionName = data.session?.name
        self.completedAt = completedAt
    }
}

// MARK: - Safety Briefing

struct AudioSafetyBriefingItem: Identifiable {
    let id: String
    let topic: String
    let notes: String?
    let conductedByName: String
    let conductedAt: Date
    let attendeeCount: Int
    let attendees: [AudioBriefingAttendeeItem]
}

extension AudioSafetyBriefingItem {
    // From AVSafetyBriefingsQuery
    init(from data: AssemblyOpsAPI.AVSafetyBriefingsQuery.Data.AvSafetyBriefing) {
        self.id = data.id
        self.topic = data.topic
        self.notes = data.notes
        self.conductedByName = "\(data.conductedBy.firstName) \(data.conductedBy.lastName)"
        self.conductedAt = DateUtils.parseISO8601(data.conductedAt) ?? Date()
        self.attendeeCount = data.attendeeCount
        self.attendees = data.attendees.map { attendee in
            AudioBriefingAttendeeItem(
                id: attendee.id,
                volunteerId: attendee.eventVolunteer.id,
                volunteerName: "\(attendee.eventVolunteer.user.firstName) \(attendee.eventVolunteer.user.lastName)"
            )
        }
    }

    // From MyAVSafetyBriefingsQuery (attendeeCount only, no full attendees list)
    init(fromMy data: AssemblyOpsAPI.MyAVSafetyBriefingsQuery.Data.MyAVSafetyBriefing) {
        self.id = data.id
        self.topic = data.topic
        self.notes = data.notes
        self.conductedByName = "\(data.conductedBy.firstName) \(data.conductedBy.lastName)"
        self.conductedAt = DateUtils.parseISO8601(data.conductedAt) ?? Date()
        self.attendeeCount = data.attendeeCount
        self.attendees = []
    }

    // From CreateAVSafetyBriefingMutation
    init(fromCreate data: AssemblyOpsAPI.CreateAVSafetyBriefingMutation.Data.CreateAVSafetyBriefing) {
        self.id = data.id
        self.topic = data.topic
        self.notes = data.notes
        self.conductedByName = "\(data.conductedBy.firstName) \(data.conductedBy.lastName)"
        self.conductedAt = DateUtils.parseISO8601(data.conductedAt) ?? Date()
        self.attendeeCount = data.attendeeCount
        self.attendees = data.attendees.map { attendee in
            AudioBriefingAttendeeItem(
                id: attendee.id,
                volunteerId: attendee.eventVolunteer.id,
                volunteerName: "\(attendee.eventVolunteer.user.firstName) \(attendee.eventVolunteer.user.lastName)"
            )
        }
    }
}

// MARK: - Briefing Attendee

struct AudioBriefingAttendeeItem: Identifiable {
    let id: String
    let volunteerId: String
    let volunteerName: String
}

// NOTE: AudioBriefingAttendeeItem GraphQL initializers are added after Apollo codegen
// runs for AV operations (AVSafetyBriefingsQuery, CreateAVSafetyBriefingMutation).

// MARK: - Equipment Summary

struct AudioEquipmentSummaryItem {
    let totalItems: Int
    let checkedOutCount: Int
    let needsRepairCount: Int
    let outOfServiceCount: Int
    let byCategory: [AudioCategorySummaryItem]
}

extension AudioEquipmentSummaryItem {
    init(from data: AssemblyOpsAPI.AVEquipmentSummaryQuery.Data.AvEquipmentSummary) {
        self.totalItems = data.totalItems
        self.checkedOutCount = data.checkedOutCount
        self.needsRepairCount = data.needsRepairCount
        self.outOfServiceCount = data.outOfServiceCount
        self.byCategory = data.byCategory.map { cat in
            AudioCategorySummaryItem(
                id: cat.category.rawValue,
                category: AudioEquipmentCategoryItem(rawValue: cat.category.rawValue) ?? .accessory,
                count: cat.count,
                checkedOutCount: cat.checkedOutCount
            )
        }
    }
}

struct AudioCategorySummaryItem: Identifiable {
    let id: String
    let category: AudioEquipmentCategoryItem
    let count: Int
    let checkedOutCount: Int
}

// NOTE: AudioCategorySummaryItem GraphQL initializer is added after Apollo codegen
// runs for AV operations (AVEquipmentSummaryQuery).
