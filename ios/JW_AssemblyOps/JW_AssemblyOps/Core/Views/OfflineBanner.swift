//
//  OfflineBanner.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 1/15/26.
//

// MARK: - Offline Banner
//
// Orange banner displayed at top of screen when device loses connectivity.
// Animates in/out based on NetworkMonitor connection status.
//
// Components:
//   - WiFi slash icon
//   - "You are offline" message
//   - "Data may be outdated" caption
//
// Behavior:
//   - Shows when NetworkMonitor.isConnected is false
//   - Slides in from top with opacity transition
//   - Orange background for visibility
//
// Dependencies:
//   - NetworkMonitor: Provides connectivity status
//
// Used by: MainTabView

import Foundation
import SwiftUI

struct OfflineBanner: View {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                Text("You are offline")
                Spacer()
                Text("Data may be outdated")
                    .font(.caption)
            }
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.orange)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

#Preview {
    VStack {
        OfflineBanner()
        Spacer()
    }
}
