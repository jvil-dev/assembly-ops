//
//  StageChecklistItems.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Stage Checklist Items
//
// Two checklist types for the Stage department:
//   - Appendix F (preShow): Items the stage crew gives to participants before they go on stage
//   - Stage Setup (stageSetup): Overseer setup checklist for configuring the stage area
//
// Checklist state is ephemeral (not persisted to backend).

import Foundation

// MARK: - Stage Checklist Type

enum StageChecklistType: String, CaseIterable {
    case preShow    = "APPENDIX_F"
    case stageSetup = "STAGE_SETUP"

    var displayName: String {
        switch self {
        case .preShow:    return "Appendix F"
        case .stageSetup: return "Stage Setup"
        }
    }

    var subtitle: String {
        switch self {
        case .preShow:
            return "Remind participants of these points immediately before going on stage."
        case .stageSetup:
            return "Overseer stage area setup checklist. Complete before each program day."
        }
    }

    var isOverseerOnly: Bool {
        self == .stageSetup
    }
}

// MARK: - Appendix F Items (Participant Pre-Show Reminders)

/// CO-160 Appendix F — 4 reminders to give participants right before they go on stage.
/// Stage crew reads or reviews these with participants backstage.
let stagePreShowItems: [AudioChecklistItem] = [
    AudioChecklistItem(
        id: "f1",
        key: "Remove any badges, lanyards, or large pins from clothing.",
        isChecked: false
    ),
    AudioChecklistItem(
        id: "f2",
        key: "Confirm microphone placement — lapel mic or handheld — with the audio crew.",
        isChecked: false
    ),
    AudioChecklistItem(
        id: "f3",
        key: "Be aware of the confidence monitor location so you can read your notes if needed.",
        isChecked: false
    ),
    AudioChecklistItem(
        id: "f4",
        key: "Enter and exit from the assigned side as indicated by floor markings.",
        isChecked: false
    ),
]

// MARK: - Stage Setup Checklist (Overseer)

/// CO-160-informed stage setup checklist for the Stage overseer.
let stageSetupItems: [AudioChecklistItem] = [
    AudioChecklistItem(
        id: "s1",
        key: "Mark participant entry and exit sides on the stage floor with tape.",
        isChecked: false
    ),
    AudioChecklistItem(
        id: "s2",
        key: "Confirm furniture positions per CO-13/S-343 layout for each program part.",
        isChecked: false
    ),
    AudioChecklistItem(
        id: "s3",
        key: "Verify microphone stands are positioned and tested with the audio crew.",
        isChecked: false
    ),
    AudioChecklistItem(
        id: "s4",
        key: "Confirm makeup sisters are ready if video is used at this event.",
        isChecked: false
    ),
    AudioChecklistItem(
        id: "s5",
        key: "Verify confidence monitor is visible from the speaker's position on stage.",
        isChecked: false
    ),
    AudioChecklistItem(
        id: "s6",
        key: "Check backstage monitors are functioning for video feed visibility.",
        isChecked: false
    ),
]
