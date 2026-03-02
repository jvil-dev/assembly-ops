//
//  AppTheme.swift
//  AssemblyOps
//
//

// MARK: - App Theme
//
// Centralized design system that extends the refined login aesthetic
// throughout the entire app. Provides consistent colors, gradients,
// shadows, spacing, and animation values.
//
// This theme creates visual cohesion between the login experience
// and the main app, with support for iOS 26 Liquid Glass design.
//
// Usage:
//   - Background: .themedBackground(scheme: colorScheme)
//   - Cards: .themedCard(scheme: colorScheme)
//   - Animations: .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
//

import SwiftUI

// MARK: - App Theme

struct AppTheme {

    // MARK: - Color Scheme Aware Colors

    /// Warm cream gradient top (light mode) / Dark gray (dark mode)
    static func backgroundTop(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(white: 0.1)
            : Color(red: 0.98, green: 0.97, blue: 0.95)
    }

    /// Warm cream gradient bottom (light mode) / Darker gray (dark mode)
    static func backgroundBottom(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(white: 0.08)
            : Color(red: 0.96, green: 0.94, blue: 0.91)
    }

    /// Card background - white in light, dark gray in dark
    static func cardBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(white: 0.15)
            : Color.white
    }

    /// Secondary card background for nested elements
    static func cardBackgroundSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(white: 0.12)
            : Color(red: 0.98, green: 0.97, blue: 0.96)
    }

    /// Primary text color
    static func textPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white
            : Color(red: 0.1, green: 0.1, blue: 0.1)
    }

    /// Secondary text color
    static func textSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.6)
            : Color(red: 0.45, green: 0.45, blue: 0.45)
    }

    /// Tertiary text color
    static func textTertiary(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.4)
            : Color(red: 0.6, green: 0.6, blue: 0.6)
    }

    /// Divider color
    static func dividerColor(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.1)
            : Color.black.opacity(0.08)
    }

    // MARK: - Theme Color

    /// Primary theme color from asset catalog
    static var themeColor: Color {
        Color("ThemeColor")
    }

    /// Theme color with opacity
    static func themeColor(opacity: Double) -> Color {
        Color("ThemeColor").opacity(opacity)
    }

    // MARK: - Status Colors

    struct StatusColors {
        // Pending - Orange/Yellow
        static let pending = Color.orange
        static let pendingBackground = Color.orange.opacity(0.12)
        static let pendingBackgroundSubtle = Color.orange.opacity(0.06)

        // Accepted - Green
        static let accepted = Color.green
        static let acceptedBackground = Color.green.opacity(0.12)
        static let acceptedBackgroundSubtle = Color.green.opacity(0.06)

        // Declined - Red
        static let declined = Color.red
        static let declinedBackground = Color.red.opacity(0.12)
        static let declinedBackgroundSubtle = Color.red.opacity(0.06)

        // Info - Blue
        static let info = Color.blue
        static let infoBackground = Color.blue.opacity(0.12)

        // Warning - Orange
        static let warning = Color.orange
        static let warningBackground = Color.orange.opacity(0.10)
    }

    // MARK: - Gradients

    /// Main background gradient matching login screens
    static func backgroundGradient(for scheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [backgroundTop(for: scheme), backgroundBottom(for: scheme)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Corner Radii

    struct CornerRadius {
        /// Large cards, modals: 24pt
        static let large: CGFloat = 24

        /// Standard cards: 16pt
        static let medium: CGFloat = 16

        /// Buttons, small cards: 14pt
        static let button: CGFloat = 14

        /// Small elements: 12pt
        static let small: CGFloat = 12

        /// Badges, tags: 8pt
        static let badge: CGFloat = 8

        /// Pills, capsules: fully rounded
        static let pill: CGFloat = 100
    }

    // MARK: - Spacing

    struct Spacing {
        /// XS: 4pt
        static let xs: CGFloat = 4

        /// S: 8pt
        static let s: CGFloat = 8

        /// M: 12pt
        static let m: CGFloat = 12

        /// L: 16pt
        static let l: CGFloat = 16

        /// XL: 24pt
        static let xl: CGFloat = 24

        /// XXL: 32pt
        static let xxl: CGFloat = 32

        /// Screen edge padding
        static let screenEdge: CGFloat = 20

        /// Card internal padding
        static let cardPadding: CGFloat = 20
    }

    // MARK: - Typography

    struct Typography {
        /// Large title: 28pt semibold
        static let largeTitle = Font.system(size: 28, weight: .semibold, design: .default)

        /// Title: 22pt semibold
        static let title = Font.system(size: 22, weight: .semibold, design: .default)

        /// Headline: 17pt semibold
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)

        /// Body: 17pt regular
        static let body = Font.system(size: 17, weight: .regular, design: .default)

        /// Body medium: 17pt medium
        static let bodyMedium = Font.system(size: 17, weight: .medium, design: .default)

        /// Subheadline: 15pt regular
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)

        /// Caption: 13pt regular
        static let caption = Font.system(size: 13, weight: .regular, design: .default)

        /// Caption bold: 13pt medium
        static let captionBold = Font.system(size: 13, weight: .medium, design: .default)

        /// Small caption: 11pt regular
        static let captionSmall = Font.system(size: 11, weight: .regular, design: .default)

        /// Monospaced for IDs/codes
        static let monospaced = Font.system(size: 15, weight: .regular, design: .monospaced)
    }

    // MARK: - Button Heights

    struct ButtonHeight {
        static let large: CGFloat = 56
        static let medium: CGFloat = 50
        static let small: CGFloat = 44
    }

    // MARK: - Animations

    /// Standard entrance animation (0.5s ease-out)
    static var entranceAnimation: Animation {
        .easeOut(duration: 0.5)
    }

    /// Entrance animation with custom delay
    static func entranceAnimation(delay: Double) -> Animation {
        .easeOut(duration: 0.5).delay(delay)
    }

    /// Calculate staggered delay for list items
    static func staggeredDelay(index: Int, baseDelay: Double = 0.05) -> Double {
        Double(index) * baseDelay
    }

    /// Quick feedback animation
    static var quickAnimation: Animation {
        .easeInOut(duration: 0.2)
    }

    /// Spring animation for bouncy effects
    static var springAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.7)
    }

    // MARK: - Shadow Definitions

    struct Shadow {
        /// Card shadow - primary layer
        static let cardPrimary = (color: Color.black.opacity(0.06), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(8))

        /// Card shadow - secondary layer for depth
        static let cardSecondary = (color: Color.black.opacity(0.04), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(2))

        /// Subtle shadow for nested elements
        static let subtle = (color: Color.black.opacity(0.05), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
    }
}

// MARK: - View Extensions

extension View {
    /// Applies the warm background gradient matching login screens
    func themedBackground(scheme: ColorScheme) -> some View {
        self.background(
            AppTheme.backgroundGradient(for: scheme)
                .ignoresSafeArea()
        )
    }

    /// Standard floating card style with layered shadows
    func themedCard(scheme: ColorScheme, cornerRadius: CGFloat = AppTheme.CornerRadius.medium) -> some View {
        self
            .background(AppTheme.cardBackground(for: scheme))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: AppTheme.Shadow.cardPrimary.color,
                radius: AppTheme.Shadow.cardPrimary.radius,
                x: AppTheme.Shadow.cardPrimary.x,
                y: AppTheme.Shadow.cardPrimary.y
            )
            .shadow(
                color: AppTheme.Shadow.cardSecondary.color,
                radius: AppTheme.Shadow.cardSecondary.radius,
                x: AppTheme.Shadow.cardSecondary.x,
                y: AppTheme.Shadow.cardSecondary.y
            )
    }

    /// Subtle nested card style
    func themedCardSecondary(scheme: ColorScheme) -> some View {
        self
            .background(AppTheme.cardBackgroundSecondary(for: scheme))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
    }

    /// Entrance animation helper - fade + slide up
    func entranceAnimation(hasAppeared: Bool, delay: Double = 0) -> some View {
        self
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .animation(AppTheme.entranceAnimation(delay: delay), value: hasAppeared)
    }

    /// Standard card padding
    func cardPadding() -> some View {
        self.padding(AppTheme.Spacing.cardPadding)
    }

    /// Screen edge padding
    func screenPadding() -> some View {
        self.padding(.horizontal, AppTheme.Spacing.screenEdge)
    }
}

// MARK: - Button Styles

/// Subtle scale-down effect for tappable cards
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Theme Colors - Light") {
    ScrollView {
        VStack(spacing: 20) {
            // Theme color
            HStack {
                Circle()
                    .fill(AppTheme.themeColor)
                    .frame(width: 40, height: 40)
                Text("Theme Color")
                Spacer()
            }

            // Status colors
            VStack(alignment: .leading, spacing: 12) {
                Text("Status Colors")
                    .font(.headline)

                HStack(spacing: 12) {
                    statusSwatch(AppTheme.StatusColors.pending, "Pending")
                    statusSwatch(AppTheme.StatusColors.accepted, "Accepted")
                    statusSwatch(AppTheme.StatusColors.declined, "Declined")
                }
            }

            // Card example
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Example")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.themeColor)
                Text("This is a floating card with the warm background")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }
            .cardPadding()
            .themedCard(scheme: .light)
        }
        .screenPadding()
        .padding(.vertical)
    }
    .themedBackground(scheme: .light)
}

#Preview("Theme Colors - Dark") {
    ScrollView {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Dark Mode Card")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.themeColor)
                Text("Cards adapt to dark mode with proper contrast")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }
            .cardPadding()
            .themedCard(scheme: .dark)
        }
        .screenPadding()
        .padding(.vertical)
    }
    .themedBackground(scheme: .dark)
    .preferredColorScheme(.dark)
}

// MARK: - Preview Helpers

@ViewBuilder
private func statusSwatch(_ color: Color, _ name: String) -> some View {
    VStack(spacing: 4) {
        Circle()
            .fill(color)
            .frame(width: 32, height: 32)
        Text(name)
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
}
