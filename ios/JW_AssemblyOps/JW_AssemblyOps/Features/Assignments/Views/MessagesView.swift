//
//  MessagesView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Messages View
//
// Placeholder screen for overseer messages feature.
// Currently displays empty state until messaging is implemented.
//
// Components:
//   - Empty state: ContentUnavailableView with message placeholder
//
// Future:
//   - Will display messages from department/event overseers
//   - To be implemented in Phase 4 (Operations)
//
// Used by: MainTabView.swift (Messages tab)

import SwiftUI

struct MessagesView: View {
  var body: some View {
      NavigationStack {
          ContentUnavailableView(
              "No Messages",
              systemImage: "envelope",
              description: Text("Messages from your overseer will appear here.")
          )
          .navigationTitle("Messages")
      }
  }
}
