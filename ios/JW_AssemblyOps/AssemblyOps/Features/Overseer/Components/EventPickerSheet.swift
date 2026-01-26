//
//  EventPickerSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Event Picker Sheet
//
// Modal list for overseers to switch between events they have access to.
// Displays event details and updates OverseerSessionState on selection.
//
// Features:
//   - Lists all events from OverseerSessionState.events
//   - EventRow shows: name, theme, date range, checkmark for selected
//   - Selection triggers loadDepartments for the new event
//   - Dismisses automatically after selection
//
// Components:
//   - EventRow: Reusable row displaying event summary with selection state
//
// Usage:
//   - Presented from OverseerDashboardView event header
//   - Available to both Event and Department Overseers
//

import SwiftUI

struct EventPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var sessionState = OverseerSessionState.shared

    var body: some View {
        NavigationStack {
            List(sessionState.events) { event in
                Button {
                    sessionState.selectedEvent = event
                    Task {
                        await sessionState.loadDepartments(for: event.id)
                    }
                    dismiss()
                } label: {
                    EventRow(event: event, isSelected: event.id == sessionState.selectedEvent?.id)
                }
            }
            .navigationTitle("Select Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct EventRow: View {
    let event: EventSummary
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)
                if let theme = event.theme {
                    Text(theme)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(formatDateRange(event.startDate, event.endDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color("ThemeColor"))
            }
        }
        .contentShape(Rectangle())
    }

    private func formatDateRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}