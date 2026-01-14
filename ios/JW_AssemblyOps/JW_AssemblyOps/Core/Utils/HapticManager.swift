//
//  HapticManager.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 1/2/26.
//

// MARK: - Haptic Manager
//
// Singleton utility for providing haptic feedback throughout the app.
//
// Methods:
//   - success(): Notification feedback for successful actions (check-in confirmed)
//   - error(): Notification feedback for failed actions (check-in failed)
//   - lightTap(): Light impact feedback for button presses
//   - mediumTap(): Medium impact feedback for more significant interactions
//
// Usage:
//   HapticManager.shared.success()
//
// Used by: AssignmentDetailView (check-in/out feedback), AssignmentsListView (filter toggle)

import UIKit

/// Manages haptic feedback throughout the app
final class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    /// Success feedback (check-in confirmed)
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Error feedback (check-in failed)
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// Light tap feedback (button press)
    func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium tap feedback
    func mediumTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
