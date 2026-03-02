//
//  AudioPostCategory.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Audio Crew Category
//
// Maps post category prefixes to Audio crew assignments.
// Used to filter and group posts by crew in the Audio department.

import Foundation

enum AudioCrewCategory: String, CaseIterable {
    case audio = "Audio"
    case video = "Video"
    case stage = "Stage"
    case it = "IT"

    var displayName: String {
        switch self {
        case .audio: return "av.crew.audio".localized
        case .video: return "av.crew.video".localized
        case .stage: return "av.crew.stage".localized
        case .it: return "av.crew.it".localized
        }
    }

    var icon: String {
        switch self {
        case .audio: return "speaker.wave.3"
        case .video: return "video"
        case .stage: return "light.overhead.left"
        case .it: return "desktopcomputer"
        }
    }

    /// Match a post's category string to a crew.
    /// Post categories use prefixes like "Audio - Operator", "Video - Camera", etc.
    static func from(postCategory: String?) -> AudioCrewCategory? {
        guard let category = postCategory else { return nil }
        let lower = category.lowercased()
        if lower.hasPrefix("audio") { return .audio }
        if lower.hasPrefix("video") { return .video }
        if lower.hasPrefix("stage") { return .stage }
        if lower.hasPrefix("it") { return .it }
        return nil
    }
}
