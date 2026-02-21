//
//  CreateVolunteerSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Create Volunteer Sheet
//
// Modal form for overseers to add new volunteers to their department.
// Uses the app's design system with warm background and styled inputs.
//
// Fields:
//   - Required: First name, last name, congregation
//   - Optional: Phone, email, notes
//   - Appointment: Publisher, Ministerial Servant, or Elder
//
// Features:
//   - Warm gradient background
//   - Themed form sections
//   - Form validation before submission
//   - Shows CredentialsSheet with volunteer ID and token on success
//

import SwiftUI
import Apollo

struct CreateVolunteerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: VolunteersViewModel
    @ObservedObject private var sessionState = OverseerSessionState.shared

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var appointment = "PUBLISHER"
    @State private var notes = ""
    @State private var isSubmitting = false
    @State private var showCredentials = false
    @State private var createdCredentials: (id: String, token: String)?

    @State private var congregations: [CongregationItem] = []
    @State private var selectedCongregation: CongregationItem?
    @State private var isLoadingCongregations = false
    @State private var errorMessage: String?

    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        selectedCongregation != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Required Fields
                    requiredFieldsCard

                    // Optional Fields
                    optionalFieldsCard

                    // Appointment
                    appointmentCard

                    // Notes
                    notesCard
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("New Volunteer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button("Create") {
                            Task { await createVolunteer() }
                        }
                        .disabled(!isFormValid)
                        .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showCredentials) {
                if let creds = createdCredentials {
                    CredentialsSheet(volunteerId: creds.id, token: creds.token) {
                        dismiss()
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
            }
        } catch {
            print("Failed to load congregations: \(error)")
        }
        isLoadingCongregations = false
    }

    private func createVolunteer() async {
        guard let eventId = sessionState.selectedEvent?.id else {
            errorMessage = "No event selected. Please go back and select an event."
            HapticManager.shared.error()
            return
        }

        // Use selectedDepartment first, fall back to claimedDepartment
        guard let departmentId = sessionState.selectedDepartment?.id
                ?? sessionState.claimedDepartment?.id else {
            errorMessage = "No department selected. Please go back and select a department."
            HapticManager.shared.error()
            return
        }

        guard let congregation = selectedCongregation else {
            errorMessage = "Please select a congregation."
            HapticManager.shared.error()
            return
        }

        isSubmitting = true
        HapticManager.shared.lightTap()

        let input = CreateVolunteerInput(
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            congregation: "\(congregation.name) - \(congregation.city)",
            phone: phone.isEmpty ? nil : phone,
            email: email.isEmpty ? nil : email,
            appointmentStatus: appointment,
            notes: notes.isEmpty ? nil : notes,
            departmentId: departmentId,
            eventId: eventId
        )

        if let result = await viewModel.createVolunteer(input: input) {
            createdCredentials = (result.volunteerId, result.token)
            HapticManager.shared.success()
            showCredentials = true
        } else {
            errorMessage = viewModel.error ?? "Failed to create volunteer. Please try again."
            HapticManager.shared.error()
        }

        isSubmitting = false
    }
}

// MARK: - Credentials Sheet

struct CredentialsSheet: View {
    @Environment(\.colorScheme) var colorScheme

    let volunteerId: String
    let token: String
    let onDismiss: () -> Void

    @State private var showCopiedToast = false
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Success icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.StatusColors.acceptedBackground)
                            .frame(width: 100, height: 100)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(AppTheme.StatusColors.accepted)
                    }
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Success message
                    VStack(spacing: AppTheme.Spacing.s) {
                        Text("Volunteer Created!")
                            .font(AppTheme.Typography.title)
                            .foregroundStyle(.primary)

                        Text("Share these login credentials with the volunteer:")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                            .multilineTextAlignment(.center)
                    }
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // Credentials card
                    VStack(spacing: AppTheme.Spacing.l) {
                        CredentialRow(label: "Volunteer ID", value: volunteerId, colorScheme: colorScheme)
                        CredentialRow(label: "Token", value: token, colorScheme: colorScheme)
                    }
                    .cardPadding()
                    .themedCard(scheme: colorScheme)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

                    // Copy button
                    Button {
                        UIPasteboard.general.string = "Volunteer ID: \(volunteerId)\nToken: \(token)"
                        HapticManager.shared.lightTap()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showCopiedToast = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeOut) {
                                showCopiedToast = false
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.on.doc")
                            Text("Copy to Clipboard")
                        }
                        .font(AppTheme.Typography.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.ButtonHeight.medium)
                        .foregroundStyle(.white)
                        .background(AppTheme.themeColor)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                    }
                    .buttonStyle(.plain)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.xl)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("Credentials")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
            .overlay(alignment: .bottom) {
                if showCopiedToast {
                    copiedToast
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private var copiedToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.StatusColors.accepted)
            Text("Copied to clipboard")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.cardBackground(for: colorScheme))
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        )
        .padding(.bottom, AppTheme.Spacing.xl)
    }
}

// MARK: - Credential Row

struct CredentialRow: View {
    let label: String
    let value: String
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    CreateVolunteerSheet(viewModel: VolunteersViewModel())
}

#Preview("Credentials") {
    CredentialsSheet(volunteerId: "VOL-12345", token: "ABC123XYZ") { }
}
