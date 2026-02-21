//
//  SuggestionTextField.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/20/26.
//

// MARK: - Suggestion Text Field
//
// A reusable text field with autocomplete suggestions dropdown.
// Shows matching existing values as the user types, with an
// "Add 'typed text'" option for new values.
//
// Usage:
//   SuggestionTextField(
//       placeholder: "Category",
//       text: $category,
//       suggestions: ["Seating", "Doors", "Exits"],
//       colorScheme: colorScheme
//   )

import SwiftUI

struct SuggestionTextField: View {
    let placeholder: String
    @Binding var text: String
    let suggestions: [String]
    let colorScheme: ColorScheme

    @FocusState private var isFocused: Bool

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredSuggestions: [String] {
        guard !trimmedText.isEmpty else {
            return suggestions
        }
        return suggestions.filter {
            $0.localizedCaseInsensitiveContains(trimmedText)
        }
    }

    private var isExactMatch: Bool {
        suggestions.contains { $0.caseInsensitiveCompare(trimmedText) == .orderedSame }
    }

    private var showDropdown: Bool {
        isFocused && !suggestions.isEmpty &&
        (!filteredSuggestions.isEmpty || !trimmedText.isEmpty)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(placeholder)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            VStack(alignment: .leading, spacing: 0) {
                TextField("", text: $text)
                    .focused($isFocused)
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

                if showDropdown {
                    suggestionDropdown
                        .padding(.top, 2)
                }
            }
        }
    }

    // MARK: - Dropdown

    private var suggestionDropdown: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !trimmedText.isEmpty && !isExactMatch {
                Button {
                    HapticManager.shared.lightTap()
                    isFocused = false
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.themeColor)
                        Text("suggestion.addNew".localized(with: trimmedText))
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.vertical, AppTheme.Spacing.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !filteredSuggestions.isEmpty {
                    Divider()
                }
            }

            ForEach(filteredSuggestions, id: \.self) { suggestion in
                Button {
                    text = suggestion
                    HapticManager.shared.lightTap()
                    isFocused = false
                } label: {
                    Text(suggestion)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, AppTheme.Spacing.m)
                        .padding(.vertical, AppTheme.Spacing.s)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if suggestion != filteredSuggestions.last {
                    Divider()
                }
            }
        }
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

#Preview {
    VStack(spacing: 20) {
        SuggestionTextField(
            placeholder: "Category",
            text: .constant("Sea"),
            suggestions: ["Seating", "Doors", "Exits"],
            colorScheme: .light
        )

        SuggestionTextField(
            placeholder: "Location",
            text: .constant(""),
            suggestions: ["Main Floor", "Balcony", "Lobby"],
            colorScheme: .light
        )
    }
    .padding()
}
