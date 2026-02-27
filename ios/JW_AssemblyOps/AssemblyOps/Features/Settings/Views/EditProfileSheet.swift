//
//  EditProfileSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/21/26.
//

// MARK: - Edit Overseer Profile Sheet
//
// Modal form for overseers to edit their own profile information.
//
// Fields:
//   - Required: First name, last name
//   - Optional: Phone
//   - Congregation: Searchable (CongregationSearchField)
//
// Features:
//   - Pre-populated from AppState.currentUser
//   - Congregation pre-selected if user already has one
//   - Patch-style update (only sends changed fields)
//   - Warm gradient background with themed form sections
//

import SwiftUI
import Apollo

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var appState: AppState

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var phone: String = ""
    @State private var congregationName: String = ""
    @State private var congregationId: String?

    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showError = false

    private let originalFirstName: String
    private let originalLastName: String
    private let originalPhone: String?
    private let originalCongregationId: String?

    init() {
        guard let user = AppState.shared.currentUser else {
            fatalError("EditProfileSheet requires a current user")
        }

        self.originalFirstName = user.firstName
        self.originalLastName = user.lastName
        self.originalPhone = user.phone
        self.originalCongregationId = user.congregationId

        _firstName = State(initialValue: user.firstName)
        _lastName = State(initialValue: user.lastName)
        _phone = State(initialValue: user.phone ?? "")
        _congregationName = State(initialValue: user.congregation ?? "")
        _congregationId = State(initialValue: user.congregationId)
    }

    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
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

            CongregationSearchField(
                selectedName: $congregationName,
                selectedId: $congregationId
            )
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

    private func saveChanges() async {
        isSubmitting = true
        HapticManager.shared.lightTap()

        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespaces)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)

        // Build patch-style input — only send changed fields

        var input = AssemblyOpsAPI.UpdateUserProfileInput()

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

        // Congregation: send whenever id OR name changed
        let originalCongName = appState.currentUser?.congregation ?? ""
        let trimmedCongName = congregationName.trimmingCharacters(in: .whitespaces)
        let congIdChanged = congregationId != originalCongregationId
        let congNameChanged = trimmedCongName != originalCongName

        if congIdChanged || congNameChanged {
            input.congregationId = congregationId.map { .some($0) } ?? .null
            input.congregation = trimmedCongName.isEmpty ? .null : .some(trimmedCongName)
        }

        do {
            let result = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.UpdateUserProfileMutation(input: input)
            )

            if let errors = result.errors, !errors.isEmpty {
                errorMessage = errors.first?.message ?? "Failed to update profile"
                HapticManager.shared.error()
                isSubmitting = false
                return
            }

            if let data = result.data?.updateUserProfile {
                // Update AppState with new profile data
                appState.currentUser = UserInfo(
                    id: data.id,
                    userId: data.userId,
                    email: data.email,
                    firstName: data.firstName,
                    lastName: data.lastName,
                    fullName: data.fullName,
                    phone: data.phone,
                    congregation: data.congregation,
                    congregationId: data.congregationId,
                    circuitCode: data.congregationRef?.circuit.code,
                    circuitId: data.congregationRef?.circuit.id,
                    appointmentStatus: appState.currentUser?.appointmentStatus,
                    isOverseer: data.isOverseer
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
    EditProfileSheet()
        .environmentObject(AppState.shared)
}
