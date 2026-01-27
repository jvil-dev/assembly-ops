//
//  EventPickerSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Event Picker Sheet
//
// Modal list for overseers to switch between events they have access to.
// Uses the app's design system with warm background and floating cards.
//
// Features:
//   - Warm gradient background
//   - Floating event cards with selection state
//   - Lists all events from OverseerSessionState.events
//   - Selection triggers loadDepartments for the new event
//   - Entrance animations
//

import SwiftUI

struct EventPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var sessionState = OverseerSessionState.shared

    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.m) {
                    ForEach(Array(sessionState.events.enumerated()), id: \.element.id) { index, event in
                        Button {
                            HapticManager.shared.lightTap()
                            sessionState.selectedEvent = event
                            Task {
                                await sessionState.loadDepartments(for: event.id)
                            }
                            dismiss()
                        } label: {
                            EventRow(
                                event: event,
                                isSelected: event.id == sessionState.selectedEvent?.id,
                                colorScheme: colorScheme
                            )
                        }
                        .buttonStyle(.plain)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.03)
                    }
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("Select Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: EventSummary
    let isSelected: Bool
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Event icon
            ZStack {
                Circle()
                    .fill(isSelected ? AppTheme.themeColor.opacity(0.15) : AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .frame(width: 48, height: 48)

                Image(systemName: "calendar")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isSelected ? AppTheme.themeColor : AppTheme.textSecondary(for: colorScheme))
            }

            // Event details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)

                if let theme = event.theme {
                    Text(theme)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .lineLimit(1)
                }

                Text(formatDateRange(event.startDate, event.endDate))
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Spacer()

            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.themeColor)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .strokeBorder(isSelected ? AppTheme.themeColor.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }

    private func formatDateRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

#Preview {
    EventPickerSheet()
}
