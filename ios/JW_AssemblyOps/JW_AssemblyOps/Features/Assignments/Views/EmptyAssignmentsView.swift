//
//  EmptyAssignmentsView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//


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