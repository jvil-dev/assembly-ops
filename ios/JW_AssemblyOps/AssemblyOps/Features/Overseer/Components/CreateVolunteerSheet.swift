//
//  CreateVolunteerSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Create Volunteer Sheet
//
// Modal form for overseers to add new volunteers to their department.
// Collects volunteer info and returns login credentials on success.
//
// Fields:
//   - Required: First name, last name, congregation
//   - Optional: Phone, email, notes
//   - Appointment: Publisher, Ministerial Servant, or Elder
//
// Features:
//   - Form validation before submission
//   - Calls VolunteersViewModel.createVolunteer()
//   - Shows CredentialsSheet with volunteer ID and token on success
//   - Auto-adds new volunteer to department list
//
// Flow:
//   1. Overseer fills form and taps Create
//   2. CreateVolunteerMutation returns volunteer ID and login token
//   3. CredentialsSheet displays credentials for sharing with volunteer
//   4. Dismiss returns to volunteer list with new entry
//

import SwiftUI

struct CreateVolunteerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: VolunteersViewModel
    @ObservedObject private var sessionState = OverseerSessionState.shared

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var congregation = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var appointment = "PUBLISHER"
    @State private var notes = ""
    @State private var isSubmitting = false
    @State private var showCredentials = false
    @State private var createdCredentials: (id: String, token: String)?

    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !congregation.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Required") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Congregation", text: $congregation)
                }

                Section("Optional") {
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }

                Section("Appointment") {
                    Picker("Appointment", selection: $appointment) {
                        Text("Publisher").tag("PUBLISHER")
                        Text("Ministerial Servant").tag("MINISTERIAL_SERVANT")
                        Text("Elder").tag("ELDER")
                    }
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Volunteer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await createVolunteer() }
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
            }
            .sheet(isPresented: $showCredentials) {
                if let creds = createdCredentials {
                    CredentialsSheet(volunteerId: creds.id, token: creds.token) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func createVolunteer() async {
        guard let departmentId = sessionState.selectedDepartment?.id,
              let eventId = sessionState.selectedEvent?.id else { return }

        isSubmitting = true

        let input = CreateVolunteerInput(
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            congregation: congregation.trimmingCharacters(in: .whitespaces),
            phone: phone.isEmpty ? nil : phone,
            email: email.isEmpty ? nil : email,
            appointmentStatus: appointment,
            notes: notes.isEmpty ? nil : notes,
            departmentId: departmentId,
            eventId: eventId
        )

        if let result = await viewModel.createVolunteer(input: input) {
            createdCredentials = (result.volunteerId, result.token)
            showCredentials = true
        }

        isSubmitting = false
    }
}

struct CredentialsSheet: View {
    let volunteerId: String
    let token: String
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)

                Text("Volunteer Created!")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Share these login credentials with the volunteer:")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                VStack(spacing: 16) {
                    CredentialRow(label: "Volunteer ID", value: volunteerId)
                    CredentialRow(label: "Token", value: token)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button("Copy to Clipboard") {
                    UIPasteboard.general.string = "Volunteer ID: \(volunteerId)\nToken: \(token)"
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("Credentials")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDismiss() }
                }
            }
        }
    }
}

struct CredentialRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}