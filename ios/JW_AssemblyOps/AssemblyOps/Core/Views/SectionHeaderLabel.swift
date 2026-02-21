//
//  SectionHeaderLabel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/21/26.
//

// MARK: - Section Header Label
//
// Reusable section header with SF Symbol icon and uppercased title.
// Used across form sheets and detail views for consistent section labeling.
//
// Parameters:
//   - icon: SF Symbol name
//   - title: Section label text (auto-uppercased)
//

import SwiftUI

struct SectionHeaderLabel: View {
    @Environment(\.colorScheme) var colorScheme

    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.themeColor)
            Text(title.uppercased())
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
        }
    }
}
