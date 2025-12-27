//
//  ErrorView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//


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