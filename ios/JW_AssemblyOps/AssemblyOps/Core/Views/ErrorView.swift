//
//  ErrorView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Error View
//
// Reusable error state view with retry functionality.
//
// Properties:
//   - message: Error description to display
//   - retryAction: Async closure called when retry is tapped

import SwiftUI

struct ErrorView: View {
    @Environment(\.colorScheme) var colorScheme

    let message: String
    let retryAction: () async -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.StatusColors.warning)

            Text("common.error".localized)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text(message)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            Button {
                HapticManager.shared.error()
                Task {
                    await retryAction()
                }
            } label: {
                Label("common.retry".localized, systemImage: "arrow.clockwise")
                    .font(AppTheme.Typography.bodyMedium)
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.themeColor)

            Spacer()
        }
        .padding(AppTheme.Spacing.screenEdge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .themedBackground(scheme: colorScheme)
    }
}

#Preview {
    ErrorView(message: "Unable to connect to server") {
        // Retry action
    }
}
