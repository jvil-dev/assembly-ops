//
//  MessagesView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

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
