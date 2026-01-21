//
//  LaunchView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Launch View
//
// Splash screen displayed during app initialization.
// Shown while AppState checks for existing auth tokens.
//
// Components:
//   - App icon and branding
//   - Loading indicator
//
// Behavior:
//   - Displayed when AppState.isLoading is true
//   - Automatically transitions once auth check completes
//
// Used by: JW_AssemblyOpsApp.swift (during initial load)

import SwiftUI

struct LaunchView: View {
  var body: some View {
      VStack(spacing: 20) {
          Image("Logo")
              .resizable()
              .scaledToFit()
              .frame(width: 120, height: 120)

          Text("AssemblyOps")
              .font(.largeTitle)
              .fontWeight(.bold)

          Text("Volunteer Scheduling Simplified")
              .font(.subheadline)
              .foregroundStyle(.secondary)

          ProgressView()
              .padding(.top, 40)
      }
      .padding()
  }
}

#Preview {
  LaunchView()
}
