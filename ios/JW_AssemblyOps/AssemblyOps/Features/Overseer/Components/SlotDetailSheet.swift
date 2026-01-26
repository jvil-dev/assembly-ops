//
//  SlotDetailSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Slot Detail Sheet
//
// Modal view showing details for a coverage matrix slot (post + session).
// Allows overseers to view assigned volunteers and add new assignments.
//
// Sections:
//   - Slot Info: Post name, session name, coverage count
//   - Assigned Volunteers: List of current assignments with check-in status
//   - Add Volunteer: Button to open VolunteerPickerSheet (if not at capacity)
//
// Components:
//   - AssignmentRow: Displays volunteer name and check-in time
//
// Features:
//   - Shows VolunteerPickerSheet for adding assignments
//   - Refreshes coverage data after successful assignment
//   - Conditionally shows "Assign Volunteer" when slots available
//

import SwiftUI

struct SlotDetailSheet: View {
    let slot: CoverageSlot
    @ObservedObject var viewModel: CoverageMatrixViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showVolunteerPicker = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Post", value: slot.postName)
                    LabeledContent("Session", value: slot.sessionName)
                    LabeledContent("Coverage", value: "\(slot.filled)/\(slot.capacity)")
                }

                Section("Assigned Volunteers") {
                    if slot.assignments.isEmpty {
                        Text("No volunteers assigned")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(slot.assignments) { assignment in
                            AssignmentRow(assignment: assignment)
                        }
                    }
                }

                if slot.filled < slot.capacity {
                    Section {
                        Button {
                            showVolunteerPicker = true
                        } label: {
                            Label("Assign Volunteer", systemImage: "plus")
                        }
                    }
                }
            }
            .navigationTitle("Slot Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showVolunteerPicker) {
                VolunteerPickerSheet(
                    postId: slot.postId,
                    sessionId: slot.sessionId
                ) { success in
                    if success {
                        Task {
                            await viewModel.loadCoverage()
                        }
                    }
                }
            }
        }
    }
}

struct AssignmentRow: View {
    let assignment: CoverageAssignment

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(assignment.volunteer.firstName) \(assignment.volunteer.lastName)")
                    .font(.body)
                if let checkIn = assignment.checkIn {
                    Text("Checked in \(checkIn.checkInTime, style: .time)")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            Spacer()
            if assignment.checkIn != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }
}
