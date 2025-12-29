//
//  LoadingView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Loading View
//
// Reusable loading indicator with customizable message.
// Displays centered spinner with optional description text.
//
// Properties:
//   - message: Text displayed below spinner (default: "Loading...")
//
// Used by: AssignmentsListView.swift (while fetching data)

import SwiftUI

struct LoadingView: View {
    var message: String = "Loading..."
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoadingView()
}
