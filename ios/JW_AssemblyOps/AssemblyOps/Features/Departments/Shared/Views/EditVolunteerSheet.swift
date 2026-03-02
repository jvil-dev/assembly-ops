//
//  EditVolunteerSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/21/26.
//

// MARK: - Edit Volunteer Sheet
//
// Modal form for overseers to edit an existing volunteer's profile.
// Mirrors CreateVolunteerSheet layout with pre-populated fields.
//
// Fields:
//   - Required: First name, last name, congregation (search)
//   - Optional: Phone, email, notes
//   - Appointment: Publisher, Ministerial Servant, or Elder
//
// Features:
//   - Pre-populated from VolunteerListItem
//   - Congregation via CongregationSearchField with pre-population
//   - Patch-style update (only sends changed fields)
//   - Warm gradient background with themed form sections
//

import SwiftUI
import Apollo

struct EditVolunteerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: VolunteerDetailViewModel

    let volunteer: VolunteerListItem

    @State private var firstName: String
    @State private var lastName: String
    @State private var phone: String
    @State private var email: String
    @State private var appointment: String
    @State private var notes: String
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    @State private var congregationName: String
    @State private var congregationId: String?

    init(volunteer: VolunteerListItem, viewModel: VolunteerDetailViewModel) {
        self.volunteer = volunteer
        self.viewModel = viewModel
        _firstName = State(initialValue: volunteer.firstName)
        _lastName = State(initialValue: volunteer.lastName)
        _phone = State(initialValue: volunteer.phone ?? "")
        _email = State(initialValue: volunteer.email ?? "")
        _appointment = State(initialValue: volunteer.appointmentStatus ?? "PUBLISHER")
        _notes = State(initialValue: "")
        _congregationName = State(initialValue: volunteer.congregation)
        _congregationId = State(initialValue: nil)
    }

    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !congregationName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    requiredFieldsCard
                    optionalFieldsCard
                    appointmentCard
                    notesCard
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("Edit Volunteer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task { await saveChanges() }
                        }
                        .disabled(!isFormValid)
                        .fontWeight(.semibold)
                    }
                }
            }
            .task {
                await prePopulateCongregation()
            }
            .alert("common.error".localized, isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("common.ok".localized) { errorMessage = nil }
            } message: {
                if let msg = errorMessage {
                    Text(msg)
                }
            }
            .onChange(of: viewModel.didUpdate) { _, didUpdate in
                if didUpdate {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Required Fields Card

    private var requiredFieldsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "person.fill", title: "Required")

            VStack(spacing: AppTheme.Spacing.m) {
                themedTextField("First Name", text: $firstName)
                themedTextField("Last Name", text: $lastName)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                    Text("Congregation")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                    CongregationSearchField(
                        selectedName: $congregationName,
                        selectedId: $congregationId
                    )
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Optional Fields Card

    private var optionalFieldsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "info.circle.fill", title: "Optional")

            VStack(spacing: AppTheme.Spacing.m) {
                themedTextField("Phone", text: $phone, keyboardType: .phonePad)
                themedTextField("Email", text: $email, keyboardType: .emailAddress, autocapitalization: .never)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Appointment Card

    private var appointmentCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "person.badge.shield.checkmark.fill", title: "Appointment")

            Picker("Appointment", selection: $appointment) {
                Text("Publisher").tag("PUBLISHER")
                Text("Ministerial Servant").tag("MINISTERIAL_SERVANT")
                Text("Elder").tag("ELDER")
            }
            .pickerStyle(.segmented)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Notes Card

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "note.text", title: "Notes")

            TextField("", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Helper Views

    private func themedTextField(
        _ label: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .words
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            TextField("", text: text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
    }

    // MARK: - Actions

    private func prePopulateCongregation() async {
        guard !volunteer.congregation.isEmpty else { return }
        // Search for the exact congregation name to get its ID for confirmed state
        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.SearchCongregationsQuery(query: volunteer.congregation),
                cachePolicy: .fetchIgnoringCacheData
            )
            if let match = result.data?.searchCongregations.first(where: {
                $0.name == volunteer.congregation
            }) {
                congregationName = match.name
                congregationId = match.id
            }
        } catch {
            // Silently fail — user can still search manually
            print("Failed to pre-populate congregation: \(error)")
        }
    }

    private func saveChanges() async {
        isSubmitting = true
        HapticManager.shared.lightTap()

        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespaces)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)

        // Build patch-style input — only send changed fields
        var input = AssemblyOpsAPI.UpdateVolunteerInput()

        if trimmedFirstName != volunteer.firstName {
            input.firstName = .some(trimmedFirstName)
        }
        if trimmedLastName != volunteer.lastName {
            input.lastName = .some(trimmedLastName)
        }
        // Only update congregation if the name changed
        let trimmedCongregation = congregationName.trimmingCharacters(in: .whitespaces)
        if trimmedCongregation != volunteer.congregation {
            input.congregation = .some(trimmedCongregation)
        }

        let originalPhone = volunteer.phone ?? ""
        if trimmedPhone != originalPhone {
            input.phone = trimmedPhone.isEmpty ? .null : .some(trimmedPhone)
        }

        let originalEmail = volunteer.email ?? ""
        if trimmedEmail != originalEmail {
            input.email = trimmedEmail.isEmpty ? .null : .some(trimmedEmail)
        }

        if appointment != (volunteer.appointmentStatus ?? "PUBLISHER") {
            input.appointmentStatus = mapAppointmentStatus(appointment)
        }

        if !trimmedNotes.isEmpty {
            input.notes = .some(trimmedNotes)
        }

        await viewModel.updateVolunteer(input: input)

        if viewModel.errorMessage != nil {
            errorMessage = viewModel.errorMessage
        }

        isSubmitting = false
    }

    private func mapAppointmentStatus(_ status: String) -> GraphQLNullable<GraphQLEnum<AssemblyOpsAPI.AppointmentStatus>> {
        switch status {
        case "PUBLISHER":
            return .some(.case(.publisher))
        case "MINISTERIAL_SERVANT":
            return .some(.case(.ministerialServant))
        case "ELDER":
            return .some(.case(.elder))
        default:
            return .none
        }
    }
}

#Preview {
    EditVolunteerSheet(
        volunteer: VolunteerListItem(
            id: "1",
            userId: "A7X9K2",
            fullName: "John Smith",
            firstName: "John",
            lastName: "Smith",
            congregation: "Central Congregation - Boston",
            phone: "+1 (555) 123-4567",
            email: "john.smith@example.com",
            appointmentStatus: "ELDER",
            departmentId: "dept-1",
            departmentName: "Attendant",
            departmentType: "ATTENDANT",
            roleId: nil,
            roleName: nil
        ),
        viewModel: VolunteerDetailViewModel(volunteerId: "1")
    )
}
