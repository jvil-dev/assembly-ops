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
//   - Required: First name, last name, congregation (dropdown)
//   - Optional: Phone, email, notes
//   - Appointment: Publisher, Ministerial Servant, or Elder
//
// Features:
//   - Pre-populated from VolunteerListItem
//   - Congregation pre-selected by matching existing value
//   - Patch-style update (only sends changed fields)
//   - Warm gradient background with themed form sections
//

import SwiftUI
import Apollo

struct EditVolunteerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: VolunteerDetailViewModel
    @ObservedObject private var sessionState = OverseerSessionState.shared

    let volunteer: VolunteerListItem

    @State private var firstName: String
    @State private var lastName: String
    @State private var phone: String
    @State private var email: String
    @State private var appointment: String
    @State private var notes: String
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    @State private var congregations: [CongregationItem] = []
    @State private var selectedCongregation: CongregationItem?
    @State private var isLoadingCongregations = false

    init(volunteer: VolunteerListItem, viewModel: VolunteerDetailViewModel) {
        self.volunteer = volunteer
        self.viewModel = viewModel
        _firstName = State(initialValue: volunteer.firstName)
        _lastName = State(initialValue: volunteer.lastName)
        _phone = State(initialValue: volunteer.phone ?? "")
        _email = State(initialValue: volunteer.email ?? "")
        _appointment = State(initialValue: volunteer.appointmentStatus ?? "PUBLISHER")
        _notes = State(initialValue: "")
    }

    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        selectedCongregation != nil
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
                    Button("Cancel") { dismiss() }
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
                await loadCongregations()
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
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

                // Congregation dropdown
                VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                    Text("Congregation")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                    if isLoadingCongregations {
                        HStack {
                            ProgressView()
                            Text("Loading congregations...")
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        }
                        .padding(AppTheme.Spacing.m)
                    } else if congregations.isEmpty {
                        Text("No congregations available")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            .padding(AppTheme.Spacing.m)
                    } else {
                        Menu {
                            ForEach(congregations) { cong in
                                Button {
                                    selectedCongregation = cong
                                    HapticManager.shared.lightTap()
                                } label: {
                                    Text("\(cong.name) - \(cong.city)")
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedCongregation.map { "\($0.name) - \($0.city)" } ?? "Select congregation")
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(selectedCongregation != nil
                                        ? (colorScheme == .dark ? .white : .primary)
                                        : AppTheme.textTertiary(for: colorScheme))
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            }
                            .padding(AppTheme.Spacing.m)
                            .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                        }
                    }
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

    private func loadCongregations() async {
        guard let circuitId = AppState.shared.currentOverseer?.circuitId else { return }

        isLoadingCongregations = true
        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.CongregationsByCircuitQuery(circuitId: circuitId),
                cachePolicy: .fetchIgnoringCacheData
            )
            if let data = result.data?.congregationsByCircuit {
                congregations = data.map { cong in
                    CongregationItem(
                        id: cong.id,
                        name: cong.name,
                        city: cong.city,
                        state: cong.state,
                        language: cong.language
                    )
                }
                // Pre-select the volunteer's current congregation by matching the stored string
                selectedCongregation = congregations.first {
                    "\($0.name) - \($0.city)" == volunteer.congregation
                }
            }
        } catch {
            print("Failed to load congregations: \(error)")
        }
        isLoadingCongregations = false
    }

    private func saveChanges() async {
        isSubmitting = true
        HapticManager.shared.lightTap()

        guard let congregation = selectedCongregation else {
            errorMessage = "Please select a congregation."
            HapticManager.shared.error()
            isSubmitting = false
            return
        }

        let congregationString = "\(congregation.name) - \(congregation.city)"

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
        if congregationString != volunteer.congregation {
            input.congregation = .some(congregationString)
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
            volunteerId: "VOL-12345",
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
            roleName: nil
        ),
        viewModel: VolunteerDetailViewModel(volunteerId: "1")
    )
}
