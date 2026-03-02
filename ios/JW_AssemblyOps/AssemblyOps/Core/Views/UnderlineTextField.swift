//
//  UnderlineTextField.swift
//  AssemblyOps
//

// MARK: - Underline Text Field
//
// Reusable form input with a small uppercase label and animated underline
// focus indicator. Used throughout the auth flow (login, registration).
//
// Usage:
//   UnderlineTextField(
//       label: "EMAIL",
//       placeholder: "your@email.com",
//       text: $email,
//       isSecure: false,
//       isFocused: focusedField == .email,
//       onSubmit: { focusedField = .password },
//       autocapitalization: .never,
//       keyboardType: .emailAddress,
//       isMonospaced: false
//   )
//   .focused($focusedField, equals: .email)

import SwiftUI

struct UnderlineTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var isFocused: Bool = false
    var onSubmit: () -> Void = {}
    var autocapitalization: TextInputAutocapitalization = .sentences
    var keyboardType: UIKeyboardType = .default
    var isMonospaced: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    private var inputFont: Font {
        isMonospaced
            ? Font.system(size: 17, weight: .regular, design: .monospaced)
            : AppTheme.Typography.body
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Floating label
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(isFocused
                                 ? AppTheme.themeColor
                                 : AppTheme.textTertiary(for: colorScheme))
                .animation(AppTheme.quickAnimation, value: isFocused)

            // Input field
            Group {
                if isSecure {
                    SecureField("", text: $text, prompt:
                        Text(placeholder)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    )
                } else {
                    TextField("", text: $text, prompt:
                        Text(placeholder)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    )
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
                }
            }
            .font(inputFont)
            .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
            .onSubmit { onSubmit() }
            .padding(.bottom, 8)
            .overlay(alignment: .bottom) {
                // Animated underline
                Rectangle()
                    .fill(isFocused
                          ? AppTheme.themeColor
                          : AppTheme.dividerColor(for: colorScheme))
                    .frame(height: isFocused ? 1.5 : 1)
                    .animation(AppTheme.quickAnimation, value: isFocused)
            }
        }
    }
}

#Preview {
    VStack(spacing: AppTheme.Spacing.xl) {
        UnderlineTextField(
            label: "EMAIL",
            placeholder: "your@email.com",
            text: .constant("hello@example.com"),
            isFocused: true
        )
        UnderlineTextField(
            label: "PASSWORD",
            placeholder: "Enter password",
            text: .constant(""),
            isSecure: true
        )
        UnderlineTextField(
            label: "VOLUNTEER ID",
            placeholder: "CA-1234",
            text: .constant("CA-5678"),
            isMonospaced: true
        )
    }
    .cardPadding()
    .themedCard(scheme: .light)
    .screenPadding()
    .padding(.vertical, 40)
    .themedBackground(scheme: .light)
}
