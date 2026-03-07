//
//  AssemblyOpsApp.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 12/26/25.
//

// MARK: - App Entry Point
//
// SwiftUI application entry point. Controls root navigation based on AppState.
//
// Routing (3 states):
//   isLoading   → LaunchView (splash)
//   !isLoggedIn → LandingView (sign in / create account)
//   isLoggedIn  → EventsHomeView (unified hub for all users)
//
// Dependencies:
//   - AppState: Global auth state manager

import SwiftUI

@main
struct AssemblyOpsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isLoading {
                    LaunchView()
                } else if appState.isLoggedIn {
                    EventsHomeView()
                        .environmentObject(appState)
                } else {
                    LandingView()
                        .environmentObject(appState)
                }
            }
            .environmentObject(appState)
        }
    }
}
