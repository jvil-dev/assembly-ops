//
//  OfflineBanner.swift
//  AssemblyOps
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
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "wifi.slash")
                Text("offline.title".localized)
                Spacer()
                Text("offline.subtitle".localized)
                    .font(AppTheme.Typography.caption)
            }
            .font(AppTheme.Typography.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, AppTheme.Spacing.l)
            .padding(.vertical, AppTheme.Spacing.m)
            .background(AppTheme.StatusColors.warning)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("offline.a11y.banner".localized)
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
