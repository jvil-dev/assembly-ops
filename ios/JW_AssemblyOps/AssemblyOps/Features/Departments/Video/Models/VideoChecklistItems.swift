//
//  VideoChecklistItems.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Video Walk-Through Checklist Items
//
// Checklist items for the Video crew from CO-160 appendices.
// Uses the same item structure as AudioChecklistItem.
//
// Appendix A: Configuring JW Library & Media Playlists (volunteer — Media assigned)
// Appendix B: Configuring Audio & Video Systems (volunteer — Media assigned)
// Appendix D: Using JW Stream to View & Download Talks (volunteer — Media assigned)
// Appendix G: AV Overseer Checklist (6 phases — overseer only)

import Foundation

enum VideoChecklistType: String, CaseIterable {
    case appendixA = "APPENDIX_A"
    case appendixB = "APPENDIX_B"
    case appendixD = "APPENDIX_D"
    case appendixG = "APPENDIX_G"

    var displayName: String {
        switch self {
        case .appendixA: return "av.walkthrough.appendixA.title".localized
        case .appendixB: return "av.walkthrough.appendixB.title".localized
        case .appendixD: return "av.walkthrough.appendixD.title".localized
        case .appendixG: return "av.walkthrough.appendixG.title".localized
        }
    }

    var subtitle: String {
        switch self {
        case .appendixA: return "av.walkthrough.appendixA.subtitle".localized
        case .appendixB: return "av.walkthrough.appendixB.subtitle".localized
        case .appendixD: return "av.walkthrough.appendixD.subtitle".localized
        case .appendixG: return "av.walkthrough.appendixG.subtitle".localized
        }
    }

    var isOverseerOnly: Bool {
        self == .appendixG
    }
}

// MARK: - Appendix A — Configuring JW Library & Media Playlists

let videoAppendixAPhases: [AudioChecklistPhase] = [
    AudioChecklistPhase(
        id: "A-P1",
        titleKey: "av.walkthrough.a.jwLibrary.title",
        items: [
            AudioChecklistItem(id: "A1-1", key: "av.walkthrough.a.jwLibrary.openApp"),
            AudioChecklistItem(id: "A1-2", key: "av.walkthrough.a.jwLibrary.settings"),
            AudioChecklistItem(id: "A1-3", key: "av.walkthrough.a.jwLibrary.secondDisplay"),
            AudioChecklistItem(id: "A1-4", key: "av.walkthrough.a.jwLibrary.yeartextOff"),
        ]
    ),
    AudioChecklistPhase(
        id: "A-P2",
        titleKey: "av.walkthrough.a.mediaPlaylist.title",
        items: [
            AudioChecklistItem(id: "A2-1", key: "av.walkthrough.a.mediaPlaylist.downloadJWPUB"),
            AudioChecklistItem(id: "A2-2", key: "av.walkthrough.a.mediaPlaylist.importJWPUB"),
            AudioChecklistItem(id: "A2-3", key: "av.walkthrough.a.mediaPlaylist.downloadWatchtower"),
        ]
    ),
    AudioChecklistPhase(
        id: "A-P3",
        titleKey: "av.walkthrough.a.importVideos.title",
        items: [
            AudioChecklistItem(id: "A3-1", key: "av.walkthrough.a.importVideos.selectFiles"),
            AudioChecklistItem(id: "A3-2", key: "av.walkthrough.a.importVideos.dragDrop"),
            AudioChecklistItem(id: "A3-3", key: "av.walkthrough.a.importVideos.verifyImport"),
            AudioChecklistItem(id: "A3-4", key: "av.walkthrough.a.importVideos.testPlayback"),
            AudioChecklistItem(id: "A3-5", key: "av.walkthrough.a.importVideos.verifyLanguage"),
        ]
    ),
    AudioChecklistPhase(
        id: "A-P4",
        titleKey: "av.walkthrough.a.playlists.title",
        items: [
            AudioChecklistItem(id: "A4-1", key: "av.walkthrough.a.playlists.createPlaylist"),
            AudioChecklistItem(id: "A4-2", key: "av.walkthrough.a.playlists.addMedia"),
            AudioChecklistItem(id: "A4-3", key: "av.walkthrough.a.playlists.setEndActions"),
            AudioChecklistItem(id: "A4-4", key: "av.walkthrough.a.playlists.verifyItems"),
        ]
    ),
]

// MARK: - Appendix B — Configuring Audio & Video Systems

let videoAppendixBItems: [AudioChecklistItem] = [
    AudioChecklistItem(id: "B1", key: "av.walkthrough.b.clickTrack"),
    AudioChecklistItem(id: "B2", key: "av.walkthrough.b.pinkNoise"),
    AudioChecklistItem(id: "B3", key: "av.walkthrough.b.sineWave"),
    AudioChecklistItem(id: "B4", key: "av.walkthrough.b.calibrationImage"),
    AudioChecklistItem(id: "B5", key: "av.walkthrough.b.whiteLevel"),
    AudioChecklistItem(id: "B6", key: "av.walkthrough.b.blackLevel"),
    AudioChecklistItem(id: "B7", key: "av.walkthrough.b.grayScale"),
]

// MARK: - Appendix D — Using JW Stream

let videoAppendixDPhases: [AudioChecklistPhase] = [
    AudioChecklistPhase(
        id: "D-P1",
        titleKey: "av.walkthrough.d.login.title",
        items: [
            AudioChecklistItem(id: "D1-1", key: "av.walkthrough.d.login.accessLink"),
            AudioChecklistItem(id: "D1-2", key: "av.walkthrough.d.login.credentials"),
        ]
    ),
    AudioChecklistPhase(
        id: "D-P2",
        titleKey: "av.walkthrough.d.livestream.title",
        items: [
            AudioChecklistItem(id: "D2-1", key: "av.walkthrough.d.livestream.accessStream"),
            AudioChecklistItem(id: "D2-2", key: "av.walkthrough.d.livestream.fullscreen"),
            AudioChecklistItem(id: "D2-3", key: "av.walkthrough.d.livestream.wideShot"),
            AudioChecklistItem(id: "D2-4", key: "av.walkthrough.d.livestream.informCoordinator"),
            AudioChecklistItem(id: "D2-5", key: "av.walkthrough.d.livestream.dissolveToStream"),
            AudioChecklistItem(id: "D2-6", key: "av.walkthrough.d.livestream.dissolveBack"),
        ]
    ),
    AudioChecklistPhase(
        id: "D-P3",
        titleKey: "av.walkthrough.d.delayStream.title",
        items: [
            AudioChecklistItem(id: "D3-1", key: "av.walkthrough.d.delayStream.accessStream"),
            AudioChecklistItem(id: "D3-2", key: "av.walkthrough.d.delayStream.pauseAndScrub"),
            AudioChecklistItem(id: "D3-3", key: "av.walkthrough.d.delayStream.fullscreen"),
            AudioChecklistItem(id: "D3-4", key: "av.walkthrough.d.delayStream.adjustGain"),
            AudioChecklistItem(id: "D3-5", key: "av.walkthrough.d.delayStream.playAndDissolve"),
            AudioChecklistItem(id: "D3-6", key: "av.walkthrough.d.delayStream.dissolveBack"),
        ]
    ),
    AudioChecklistPhase(
        id: "D-P4",
        titleKey: "av.walkthrough.d.downloaded.title",
        items: [
            AudioChecklistItem(id: "D4-1", key: "av.walkthrough.d.downloaded.downloadFile"),
            AudioChecklistItem(id: "D4-2", key: "av.walkthrough.d.downloaded.addToPlaylist"),
            AudioChecklistItem(id: "D4-3", key: "av.walkthrough.d.downloaded.followShotGuidelines"),
        ]
    ),
]

// Reuse Appendix G phases (identical for all AV crews)
let videoAppendixGPhases: [AudioChecklistPhase] = appendixGPhases
