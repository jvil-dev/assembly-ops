//
//  StageModels.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Stage Crew Models
//
// Data models for the Stage department (CO-160 Ch. 3).
// Stage crew manages participant coordination, stage configuration,
// and makeup — NOT AV equipment.

import SwiftUI

// MARK: - Stage Role

/// Stage crew assignment roles (CO-160 Ch. 3)
enum StageRole: String, CaseIterable, Identifiable {
    case micAdjuster        = "MIC_ADJUSTER"
    case participantReminder = "PARTICIPANT_REMINDER"
    case stageConfiguration = "STAGE_CONFIGURATION"
    case makeupAssistant    = "MAKEUP_ASSISTANT"
    case appearanceCheck    = "APPEARANCE_CHECK"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .micAdjuster:         return "Mic Adjuster"
        case .participantReminder: return "Participant Reminder"
        case .stageConfiguration:  return "Stage Configuration"
        case .makeupAssistant:     return "Makeup Assistant"
        case .appearanceCheck:     return "Appearance Check"
        }
    }

    var icon: String {
        switch self {
        case .micAdjuster:         return "microphone"
        case .participantReminder: return "checklist"
        case .stageConfiguration:  return "square.3.layers.3d"
        case .makeupAssistant:     return "sparkles"
        case .appearanceCheck:     return "person.crop.rectangle.badge.checkmark"
        }
    }

    var description: String {
        switch self {
        case .micAdjuster:
            return "Adjusts microphone positions for each participant going on stage. Works closely with the audio crew."
        case .participantReminder:
            return "Gives Appendix F reminders to participants immediately before they go on stage. Ensures they are prepared."
        case .stageConfiguration:
            return "Sets up stage furniture and floor markings per the program schedule. Coordinates with Installation."
        case .makeupAssistant:
            return "Applies makeup to participants as needed when video is used. Sisters only; uses disposable supplies."
        case .appearanceCheck:
            return "Conducts a final appearance check for participants near the stage entrance before they proceed."
        }
    }
}

// MARK: - Stage Configuration Notes

/// Stage layout notes stored locally per event (not backend-persisted).
struct StageConfigNotes {
    var entryIsLeft: Bool = true          // true = left, false = right
    var exitIsLeft: Bool = false
    var bothSidesEntry: Bool = false
    var furnitureNotes: String = ""
    var floorMarksConfirmed: Bool = false
    var confidenceMonitorChecked: Bool = false
    var additionalNotes: String = ""
}

// MARK: - Makeup Status

/// Makeup coordination state stored locally per event.
struct MakeupStatus {
    var videoInUse: Bool = false
    var disposableSuppliesAvailable: Bool = false
    var additionalNotes: String = ""
}
