//
//  VolunteerDetailView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Volunteer Detail View
//
// Detail screen showing complete volunteer information.
// Navigated to from VolunteerListView when tapping a volunteer row.
//
// Parameters:
//   - volunteer: VolunteerListItem containing all volunteer data
//   - isEditable: Whether this volunteer can be modified (department-scoped)
//
// Sections:
//   - Personal Information: Name, congregation, phone, email
//   - Role: Appointment status, department, assigned role
//   - Login Credentials: Volunteer ID with copy button
//   - Remove (editable only): Delete volunteer from department
//
// Features:
//   - Conditional editing based on isEditable flag
//   - Copy credentials to clipboard for sharing
//   - Confirmation dialog before removal
//
// Access Control:
//   - Editable when viewing own department volunteers
//   - Read-only when viewing cross-department roster
//

import SwiftUI

struct VolunteerDetailView: View {
    let volunteer: VolunteerListItem
    let isEditable: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    var body: some View {
        List {
            Section("Personal Information") {
                LabeledContent("Name", value: volunteer.fullName)
                LabeledContent("Congregation", value: volunteer.congregation)
                if let phone = volunteer.phone, !phone.isEmpty {
                    LabeledContent("Phone", value: phone)
                }
                if let email = volunteer.email, !email.isEmpty {
                    LabeledContent("Email", value: email)
                }
            }

            Section("Role") {
                if let appointment = volunteer.appointmentStatus {
                    LabeledContent("Appointment", value: formatAppointment(appointment))
                }
                if let department = volunteer.departmentName {
                    LabeledContent("Department", value: department)
                }
                if let role = volunteer.roleName {
                    LabeledContent("Role", value: role)
                }
            }

            Section("Login Credentials") {
                LabeledContent("Volunteer ID", value: volunteer.volunteerId)
                Button("Copy Credentials") {
                    UIPasteboard.general.string = "Volunteer ID: \(volunteer.volunteerId)"
                }
            }

            if isEditable {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Remove from Department")
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle(volunteer.firstName)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Remove Volunteer",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                // TODO: Call delete mutation
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove \(volunteer.fullName) from your department?")
        }
    }

    private func formatAppointment(_ status: String) -> String {
        switch status {
        case "PUBLISHER":
            return "Publisher"
        case "MINISTERIAL_SERVANT":
            return "Ministerial Servant"
        case "ELDER":
            return "Elder"
        default:
            return status
        }
    }
}
