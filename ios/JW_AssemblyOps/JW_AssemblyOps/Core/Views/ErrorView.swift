//
//  ErrorView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Error View
//
// Reusable error state view with retry functionality.
// Uses iOS ContentUnavailableView for consistent system styling.
//
// Properties:
//   - message: Error description to display
//   - retryAction: Async closure called when "Try Again" is tapped
//
// Components:
//   - Warning icon
//   - Error message
//   - "Try Again" button
//
// Used by: AssignmentsListView.swift (on fetch failure)

import SwiftUI

struct ErrorView: View {
    let message: String
    let retryAction: () async -> Void
    
    var body: some View {
        ContentUnavailableView {
            Label("Error", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task {
                    await retryAction()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ErrorView(message: "Unable to connect to server") {
        // Retry action
    }
}