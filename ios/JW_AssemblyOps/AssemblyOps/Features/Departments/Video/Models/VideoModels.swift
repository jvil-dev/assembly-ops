//
//  VideoModels.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Video Crew Models
//
// Re-exports AV domain models scoped to the Video crew.
// The Video crew manages cameras, switcher, media players,
// LED panels, stage lighting, and related equipment (CO-160 Ch. 4).
//
// All GraphQL types are shared with AudioVideo — this file provides
// Video-specific filtering and display helpers.

import Foundation
import SwiftUI

// MARK: - Video Equipment Categories (CO-160 Ch. 4)

extension AudioEquipmentCategoryItem {
    /// Returns true if this category is relevant to the Video crew.
    var isVideoRelevant: Bool {
        AudioEquipmentCategoryItem.videoRelevantCategories.contains(self)
    }
}

// MARK: - Video Shot Types (CO-160 Ch. 4:45-59)

enum VideoShotType: String, CaseIterable, Identifiable {
    case mediumCloseUp     = "MEDIUM_CLOSE_UP"
    case stageWide         = "STAGE_WIDE"
    case transitionShot    = "TRANSITION_SHOT"
    case interviewMidShot  = "INTERVIEW_MID_SHOT"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mediumCloseUp:    return "video.shot.mediumCloseUp".localized
        case .stageWide:        return "video.shot.stageWide".localized
        case .transitionShot:   return "video.shot.transition".localized
        case .interviewMidShot: return "video.shot.interviewMid".localized
        }
    }

    var icon: String {
        switch self {
        case .mediumCloseUp:    return "person.crop.rectangle"
        case .stageWide:        return "rectangle.expand.diagonal"
        case .transitionShot:   return "arrow.left.arrow.right"
        case .interviewMidShot: return "person.2.crop.square.stack"
        }
    }

    var description: String {
        switch self {
        case .mediumCloseUp:    return "video.shot.mediumCloseUp.desc".localized
        case .stageWide:        return "video.shot.stageWide.desc".localized
        case .transitionShot:   return "video.shot.transition.desc".localized
        case .interviewMidShot: return "video.shot.interviewMid.desc".localized
        }
    }
}
