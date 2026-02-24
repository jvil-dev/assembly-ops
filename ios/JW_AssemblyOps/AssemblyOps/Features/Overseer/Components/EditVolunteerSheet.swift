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

    let volunteer: VolunteerListItem

    @State private var firstName: String
    @State private var lastName: String
    @State private var phone: String
    @State private var email: String
    @State private var appointment: String
    @State private var notes: String
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var selectedRoleId: String?

    @State private var circuits: [CircuitItem] = []
    @State private var selectedCircuit: CircuitItem?
    @State private var congregations: [CongregationItem] = []
    @State private var selectedCongregation: CongregationItem?
    @State private var isLoadingCircuits = false
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
        _selectedRoleId = State(initialValue: volunteer.roleId)
    }

    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        // Allow saving if a congregation is selected, OR if the volunteer already has one
        // and the overseer hasn't picked a new circuit yet (congregation unchanged)
        (selectedCongregation != nil || !volunteer.congregation.isEmpty)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    requiredFieldsCard
                    optionalFieldsCard
                    appointmentCard
                    if !viewModel.roles.isEmpty {
                        roleCard
                    }
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
                if AppState.shared.currentOverseer?.circuitId == nil {
                    await loadAllCircuits()
                }
                if let eventId = OverseerSessionState.shared.selectedEvent?.id {
                    await viewModel.loadRoles(eventId: eventId)
                }
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

                // Circuit picker (shown when overseer has no circuitId set)
                if AppState.shared.currentOverseer?.circuitId == nil {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                        Text("Circuit")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                        if isLoadingCircuits {
                            HStack {
                                ProgressView()
                                Text("Loading circuits...")
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                            }
                            .padding(AppTheme.Spacing.m)
                        } else {
                            Menu {
                                ForEach(circuits) { circuit in
                                    Button {
                                        Task { await loadCongregationsForCircuit(circuit) }
                                        HapticManager.shared.lightTap()
                                    } label: {
                                        Text(circuit.code)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedCircuit?.code ?? "Select a circuit")
                                        .font(AppTheme.Typography.body)
                                        .foregroundStyle(selectedCircuit != nil
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

                // Congregation dropdown
                if AppState.shared.currentOverseer?.circuitId != nil || selectedCircuit != nil {
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

    // MARK: - Role Card

    private var roleCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "person.badge.key.fill", title: "Role")

            VStack(spacing: 0) {
                roleRow(id: nil, name: "None", isLast: false)
                ForEach(Array(viewModel.roles.enumerated()), id: \.element.id) { index, role in
                    roleRow(id: role.id, name: role.name, isLast: index == viewModel.roles.count - 1)
                }
            }
            .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private func roleRow(id: String?, name: String, isLast: Bool) -> some View {
        Button {
            selectedRoleId = id
            HapticManager.shared.lightTap()
        } label: {
            VStack(spacing: 0) {
                HStack {
                    Text(name)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(id == nil
                            ? AppTheme.textTertiary(for: colorScheme)
                            : (colorScheme == .dark ? .white : .primary))
                    Spacer()
                    Image(systemName: selectedRoleId == id ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(selectedRoleId == id
                            ? AppTheme.themeColor
                            : AppTheme.textTertiary(for: colorScheme))
                }
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.vertical, AppTheme.Spacing.m)

                if !isLast {
                    Divider()
                        .padding(.leading, AppTheme.Spacing.m)
                }
            }
        }
        .buttonStyle(.plain)
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
        guard let circuitId = AppState.shared.currentOverseer?.circuitId else {
            // No circuitId — circuit picker will be shown instead
            return
        }
        await loadCongregationsForCircuitId(circuitId, preselectMatching: volunteer.congregation)
    }

    private func loadAllCircuits() async {
        isLoadingCircuits = true
        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.CircuitsQuery(region: .none, language: .none),
                cachePolicy: .fetchIgnoringCacheData
            )
            if let data = result.data?.circuits {
                circuits = data.map { CircuitItem(id: $0.id, code: $0.code, region: $0.region, language: $0.language) }
            }
        } catch {
            print("Failed to load circuits: \(error)")
        }
        isLoadingCircuits = false
    }

    private func loadCongregationsForCircuit(_ circuit: CircuitItem) async {
        selectedCircuit = circuit
        selectedCongregation = nil
        congregations = []
        await loadCongregationsForCircuitId(circuit.id, preselectMatching: volunteer.congregation)
    }

    private func loadCongregationsForCircuitId(_ circuitId: String, preselectMatching match: String) async {
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
                    "\($0.name) - \($0.city)" == match
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
        // Only update congregation if the user explicitly picked a new one
        if let congregation = selectedCongregation {
            let congregationString = "\(congregation.name) - \(congregation.city)"
            if congregationString != volunteer.congregation {
                input.congregation = .some(congregationString)
            }
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

        if selectedRoleId != volunteer.roleId {
            input.roleId = selectedRoleId.map { .some($0) } ?? .null
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
            roleId: nil,
            roleName: nil
        ),
        viewModel: VolunteerDetailViewModel(volunteerId: "1")
    )
}
