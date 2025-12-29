//
//  JW_AssemblyOpsApp.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/26/25.
//

// MARK: - App Entry Point
//
// SwiftUI application entry point and root view coordinator.
// Controls navigation between auth flow and main app based on login state.
//
// View States:
//   - isLoading = true: Show LaunchView (splash screen)
//   - isLoggedIn = false: Show LoginView
//   - isLoggedIn = true: Show MainTabView
//
// State Management:
//   - AppState singleton injected as EnvironmentObject
//   - All child views can access via @EnvironmentObject
//
// Flow:
//   1. App launches → AppState.checkAuthState() runs
//   2. LaunchView shown during auth check
//   3. Transitions to LoginView or MainTabView based on token validity
//
// Dependencies:
//   - AppState: Global auth state manager
//   - LaunchView, LoginView, MainTabView: Root-level views

import SwiftUI

@main
struct JW_AssemblyOpsApp: App {
    @StateObject private var appState = AppState.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isLoading {
                    // Splash screen while checking auth
                    LaunchView()
                } else if appState.isLoggedIn {
                    // Main app content
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(appState)
        }
    }
}
