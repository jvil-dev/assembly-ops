//
//  DepartmentPickerSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Department Picker Sheet
//
// Modal list for Event Overseers to switch between departments.
// Department Overseers are locked to their claimed department.
//
// Features:
//   - Lists all departments in the selected event
//   - Shows volunteer count per department
//   - Checkmark indicates currently selected department
//   - Selection updates OverseerSessionState.selectedDepartment
//
// Usage:
//   - Only accessible to Event Overseers (isEventOverseer == true)
//   - Presented from OverseerDashboardView department selector
//

import SwiftUI

struct DepartmentPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var sessionState = OverseerSessionState.shared

    var body: some View {
        NavigationStack {
            List(sessionState.departments) { department in
                Button {
                    sessionState.selectDepartment(department)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(department.name)
                                .font(.headline)
                            Text("\(department.volunteerCount) volunteers")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if department.id == sessionState.selectedDepartment?.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color("ThemeColor"))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Select Department")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
