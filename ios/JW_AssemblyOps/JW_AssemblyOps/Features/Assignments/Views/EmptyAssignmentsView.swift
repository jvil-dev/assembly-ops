//
//  EmptyAssignmentsView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Empty Assignments View
//
// Empty state displayed when volunteer has no schedule assignments.
// Uses iOS ContentUnavailableView for consistent system styling.
//
// Components:
//   - Icon: Calendar with clock badge
//   - Title: "No Assignments Yet"
//   - Description: Explains assignments come from overseer
//
// Used by: AssignmentsListView.swift (when assignments array is empty)

import SwiftUI

struct EmptyAssignmentsView: View {
    var body: some View {
        ContentUnavailableView(
            "No Assignments Yet",
            systemImage: "calendar.badge.clock",
            description: Text("Your schedule will appear here once your overseer assigns you to posts.")
        )
    }
}

#Preview {
    EmptyAssignmentsView()
}