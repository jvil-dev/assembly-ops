//
//  LoadingView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Loading View
//
// Reusable loading indicator with customizable message.
// Displays centered spinner with optional description text.
//
// Properties:
//   - message: Text displayed below spinner (default: localized "Loading...")

import SwiftUI

struct LoadingView: View {
    @Environment(\.colorScheme) var colorScheme

    var message: String = "common.loading".localized

    var body: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(AppTheme.themeColor)
            Text(message)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .themedBackground(scheme: colorScheme)
    }
}

#Preview {
    LoadingView()
}
