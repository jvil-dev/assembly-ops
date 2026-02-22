//
//  EditOverseerProfileSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/21/26.
//

// MARK: - Edit Overseer Profile Sheet
//
// Modal form for overseers to edit their own profile information.
// Mirrors the mandatory first-run profile setup but with edit capability.
//
// Fields:
//   - Required: First name, last name
//   - Optional: Phone
//   - Circuit: Dropdown (filtered by available circuits)
//   - Congregation: Dropdown (filtered by selected circuit)
//
// Features:
//   - Pre-populated from AppState.currentOverseer
//   - Circuit and congregation pre-selected by matching IDs
//   - Patch-style update (only sends changed fields)
//   - Warm gradient background with themed form sections
//

import SwiftUI
import Apollo

struct EditOverseerProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var appState: AppState

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var phone: String = ""

    @State private var circuits: [CircuitItem] = []
    @State private var congregations: [CongregationItem] = []
    @State private var selectedCircuit: CircuitItem?
    @State private var selectedCongregation: CongregationItem?

    @State private var isLoadingCircuits = false
    @State private var isLoadingCongregations = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showError = false

    private let originalFirstName: String
    private let originalLastName: String
    private let originalPhone: String?
    private let originalCongregationId: String?
    private let originalCircuitId: String?

    init() {
        guard let overseer = AppState.shared.currentOverseer else {
            fatalError("EditOverseerProfileSheet requires a current overseer")
        }

        self.originalFirstName = overseer.firstName
        self.originalLastName = overseer.lastName
        self.originalPhone = overseer.phone
        self.originalCongregationId = overseer.congregationId
        self.originalCircuitId = overseer.circuitId

        _firstName = State(initialValue: overseer.firstName)
        _lastName = State(initialValue: overseer.lastName)
        _phone = State(initialValue: overseer.phone ?? "")
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
                    congregationCard
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("Edit Profile")
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
                await loadCircuits()
            }
            .onChange(of: errorMessage) { _, newValue in
                if newValue != nil {
                    showError = true
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let msg = errorMessage {
                    Text(msg)
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
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Congregation Card

    private var congregationCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "building.2.fill", title: "Congregation")

            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                // Circuit Picker
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
                                    Task { await loadCongregations(for: circuit) }
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

                // Congregation Picker (shown after circuit selection)
                if selectedCircuit != nil {
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
                            Text("No congregations found for this circuit")
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
                                    Text(selectedCongregation.map { "\($0.name) - \($0.city)" } ?? "Select a congregation")
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

    private func loadCircuits() async {
        isLoadingCircuits = true
        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.CircuitsQuery(region: .none, language: .none),
                cachePolicy: .fetchIgnoringCacheData
            )
            if let data = result.data?.circuits {
                circuits = data.map { circuit in
                    CircuitItem(
                        id: circuit.id,
                        code: circuit.code,
                        region: circuit.region,
                        language: circuit.language
                    )
                }

                // Pre-select circuit by matching original circuit ID
                if let origCircuitId = originalCircuitId {
                    selectedCircuit = circuits.first { $0.id == origCircuitId }
                    if let circuit = selectedCircuit {
                        await loadCongregations(for: circuit)
                    }
                }
            }
        } catch {
            errorMessage = "Failed to load circuits: \(error.localizedDescription)"
        }
        isLoadingCircuits = false
    }

    private func loadCongregations(for circuit: CircuitItem) async {
        selectedCircuit = circuit
        selectedCongregation = nil
        congregations = []
        isLoadingCongregations = true

        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.CongregationsByCircuitQuery(circuitId: circuit.id),
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

                // Pre-select congregation by matching original congregation ID
                if let origCongregationId = originalCongregationId {
                    selectedCongregation = congregations.first { $0.id == origCongregationId }
                }
            }
        } catch {
            errorMessage = "Failed to load congregations: \(error.localizedDescription)"
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

        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespaces)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)

        // Build patch-style input — only send changed fields
        var input = AssemblyOpsAPI.UpdateAdminProfileInput()

        if trimmedFirstName != originalFirstName {
            input.firstName = .some(trimmedFirstName)
        }
        if trimmedLastName != originalLastName {
            input.lastName = .some(trimmedLastName)
        }

        let originalPhone = originalPhone ?? ""
        if trimmedPhone != originalPhone {
            input.phone = trimmedPhone.isEmpty ? .null : .some(trimmedPhone)
        }

        if congregation.id != originalCongregationId {
            input.congregationId = .some(congregation.id)
        }

        do {
            let result = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.UpdateAdminProfileMutation(input: input)
            )

            if let errors = result.errors, !errors.isEmpty {
                errorMessage = errors.first?.message ?? "Failed to update profile"
                HapticManager.shared.error()
                isSubmitting = false
                return
            }

            if let data = result.data?.updateAdminProfile {
                // Update AppState with new profile data
                appState.currentOverseer = OverseerInfo(
                    id: data.id,
                    email: data.email,
                    fullName: data.fullName,
                    firstName: data.firstName,
                    lastName: data.lastName,
                    phone: data.phone,
                    congregationId: data.congregationId,
                    circuitId: data.congregationRef?.circuit.id,
                    overseerType: appState.currentOverseer?.overseerType ?? ""
                )
                HapticManager.shared.success()
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
        isSubmitting = false
    }
}

#Preview {
    EditOverseerProfileSheet()
        .environmentObject(AppState.shared)
}
