//
//  AudioChecklistItems.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Audio Walk-Through Checklist Items
//
// Hardcoded checklist items from CO-160 appendices.
// Items are localized via Localizable.strings keys.
//
// Appendix E: Reminders During Walk-Throughs (11 items)
// Appendix F: Reminders Before Going on Stage (4 items)
// Appendix G: Audio Overseer Checklist (~25 items in 6 phases, overseer-only)

import Foundation

enum AudioChecklistType: String, CaseIterable {
    case appendixE = "APPENDIX_E"
    case appendixF = "APPENDIX_F"
    case appendixG = "APPENDIX_G"

    var displayName: String {
        switch self {
        case .appendixE: return "av.walkthrough.appendixE.title".localized
        case .appendixF: return "av.walkthrough.appendixF.title".localized
        case .appendixG: return "av.walkthrough.appendixG.title".localized
        }
    }

    var subtitle: String {
        switch self {
        case .appendixE: return "av.walkthrough.appendixE.subtitle".localized
        case .appendixF: return "av.walkthrough.appendixF.subtitle".localized
        case .appendixG: return "av.walkthrough.appendixG.subtitle".localized
        }
    }

    /// Appendix G is restricted to overseers only
    var isOverseerOnly: Bool {
        self == .appendixG
    }
}

struct AudioChecklistItem: Identifiable {
    let id: String
    let key: String
    var isChecked: Bool = false

    var displayText: String {
        key.localized
    }
}

// MARK: - Appendix E — Reminders During Walk-Throughs

let appendixEItems: [AudioChecklistItem] = [
    AudioChecklistItem(id: "E1", key: "av.walkthrough.e.cellPhonesAirplaneMode"),
    AudioChecklistItem(id: "E2", key: "av.walkthrough.e.dontPullLectern"),
    AudioChecklistItem(id: "E3", key: "av.walkthrough.e.micDistance"),
    AudioChecklistItem(id: "E4", key: "av.walkthrough.e.projectVoice"),
    AudioChecklistItem(id: "E5", key: "av.walkthrough.e.speakingSoftly"),
    AudioChecklistItem(id: "E6", key: "av.walkthrough.e.speakingLoudly"),
    AudioChecklistItem(id: "E7", key: "av.walkthrough.e.popping"),
    AudioChecklistItem(id: "E8", key: "av.walkthrough.e.feedback"),
    AudioChecklistItem(id: "E9", key: "av.walkthrough.e.coughSneeze"),
    AudioChecklistItem(id: "E10", key: "av.walkthrough.e.interviews"),
    AudioChecklistItem(id: "E11", key: "av.walkthrough.e.stageEntryExit"),
]

// MARK: - Appendix F — Reminders Before Going on Stage

let appendixFItems: [AudioChecklistItem] = [
    AudioChecklistItem(id: "F1", key: "av.walkthrough.f.cellPhonesAirplaneMode"),
    AudioChecklistItem(id: "F2", key: "av.walkthrough.f.dontPullLectern"),
    AudioChecklistItem(id: "F3", key: "av.walkthrough.f.projectVoice"),
    AudioChecklistItem(id: "F4", key: "av.walkthrough.f.stageExitSide"),
]

// MARK: - Appendix G — AV Overseer Checklist (Phased)

struct AudioChecklistPhase: Identifiable {
    let id: String
    let titleKey: String
    var items: [AudioChecklistItem]

    var displayTitle: String {
        titleKey.localized
    }
}

let appendixGPhases: [AudioChecklistPhase] = [
    AudioChecklistPhase(
        id: "G-P1",
        titleKey: "av.walkthrough.g.phase1.title",
        items: [
            AudioChecklistItem(id: "G1-1", key: "av.walkthrough.g.phase1.jwHubLogin"),
            AudioChecklistItem(id: "G1-2", key: "av.walkthrough.g.phase1.reviewCO160"),
            AudioChecklistItem(id: "G1-3", key: "av.walkthrough.g.phase1.checkWithOverseer"),
            AudioChecklistItem(id: "G1-4", key: "av.walkthrough.g.phase1.reviewPreviousNotes"),
        ]
    ),
    AudioChecklistPhase(
        id: "G-P2",
        titleKey: "av.walkthrough.g.phase2.title",
        items: [
            AudioChecklistItem(id: "G2-1", key: "av.walkthrough.g.phase2.downloadMedia"),
            AudioChecklistItem(id: "G2-2", key: "av.walkthrough.g.phase2.reviewOutlines"),
            AudioChecklistItem(id: "G2-3", key: "av.walkthrough.g.phase2.recruitVolunteers"),
            AudioChecklistItem(id: "G2-4", key: "av.walkthrough.g.phase2.planInstallation"),
            AudioChecklistItem(id: "G2-5", key: "av.walkthrough.g.phase2.verifyEquipment"),
        ]
    ),
    AudioChecklistPhase(
        id: "G-P3",
        titleKey: "av.walkthrough.g.phase3.title",
        items: [
            AudioChecklistItem(id: "G3-1", key: "av.walkthrough.g.phase3.reviewPlan"),
            AudioChecklistItem(id: "G3-2", key: "av.walkthrough.g.phase3.remindPPE"),
            AudioChecklistItem(id: "G3-3", key: "av.walkthrough.g.phase3.verifyItems"),
            AudioChecklistItem(id: "G3-4", key: "av.walkthrough.g.phase3.confirmCrewAssignments"),
        ]
    ),
    AudioChecklistPhase(
        id: "G-P4",
        titleKey: "av.walkthrough.g.phase4.title",
        items: [
            AudioChecklistItem(id: "G4-1", key: "av.walkthrough.g.phase4.safetyTalk"),
            AudioChecklistItem(id: "G4-2", key: "av.walkthrough.g.phase4.equipmentTest"),
            AudioChecklistItem(id: "G4-3", key: "av.walkthrough.g.phase4.cameraPositions"),
            AudioChecklistItem(id: "G4-4", key: "av.walkthrough.g.phase4.audioLevels"),
            AudioChecklistItem(id: "G4-5", key: "av.walkthrough.g.phase4.videoSwitching"),
        ]
    ),
    AudioChecklistPhase(
        id: "G-P5",
        titleKey: "av.walkthrough.g.phase5.title",
        items: [
            AudioChecklistItem(id: "G5-1", key: "av.walkthrough.g.phase5.walkThroughs"),
            AudioChecklistItem(id: "G5-2", key: "av.walkthrough.g.phase5.monitorQuality"),
            AudioChecklistItem(id: "G5-3", key: "av.walkthrough.g.phase5.addressIssues"),
            AudioChecklistItem(id: "G5-4", key: "av.walkthrough.g.phase5.coordinateStage"),
        ]
    ),
    AudioChecklistPhase(
        id: "G-P6",
        titleKey: "av.walkthrough.g.phase6.title",
        items: [
            AudioChecklistItem(id: "G6-1", key: "av.walkthrough.g.phase6.disassemblyBriefing"),
            AudioChecklistItem(id: "G6-2", key: "av.walkthrough.g.phase6.inventoryCheck"),
            AudioChecklistItem(id: "G6-3", key: "av.walkthrough.g.phase6.damageReport"),
            AudioChecklistItem(id: "G6-4", key: "av.walkthrough.g.phase6.handoffNotes"),
        ]
    ),
]
