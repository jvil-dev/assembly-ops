//
//  EmptyAssignmentsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Empty Assignments View
//
// Empty state displayed when volunteer has no schedule assignments.
//
// Used by: AssignmentsListView.swift (when assignments array is empty)

import SwiftUI

struct EmptyAssignmentsView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Text("No Assignments Yet")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("Your schedule will appear here once your overseer assigns you to posts.")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppTheme.Spacing.screenEdge)
        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }
}

#Preview {
    EmptyAssignmentsView()
}
