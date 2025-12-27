//
//  JW_AssemblyOpsApp.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/26/25.
//

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
