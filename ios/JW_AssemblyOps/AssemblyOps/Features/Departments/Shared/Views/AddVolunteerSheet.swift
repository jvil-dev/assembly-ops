//
//  AddVolunteerSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/25/26.
//

// MARK: - Add Volunteer Sheet
//
// Two paths to invite volunteers:
//
//   1. Share Access Code (primary) — show department code with copy + share.
//      Volunteers enter it in the app to join instantly.
//
//   2. Add by User ID (manual) — overseer types a volunteer's 6-char User ID
//      and adds them directly. Shows success alert on completion.
//

import SwiftUI

struct AddVolunteerSheet: View {
    @ObservedObject var viewModel: VolunteersViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var userIdInput = ""
    @State private var copiedCode = false
    @State private var showError = false
    @State private var addMode: AddMode = .byUserId

    // Non-app form fields
    @State private var nonAppFirstName = ""
    @State private var nonAppLastName = ""
    @State private var nonAppCongregationName = ""
    @State private var nonAppCongregationId: String?
    @State private var nonAppPhone = ""
    @State private var nonAppAppointment: AssemblyOpsAPI.AppointmentStatus = .publisher

    enum AddMode: String, CaseIterable {
        case byUserId = "By User ID"
        case nonApp = "Non-App User"
    }

    private var accessCode: String? {
        EventSessionState.shared.claimedDepartment?.accessCode
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Mode picker
                    Picker("Add Mode", selection: $addMode) {
                        ForEach(AddMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    if addMode == .byUserId {
                        // Section 1 — Access Code (primary)
                        accessCodeSection
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.04)

                        // Divider
                        HStack(spacing: AppTheme.Spacing.m) {
                            Rectangle()
                                .fill(AppTheme.textTertiary(for: colorScheme).opacity(0.3))
                                .frame(height: 1)
                            Text("addVolunteer.or".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            Rectangle()
                                .fill(AppTheme.textTertiary(for: colorScheme).opacity(0.3))
                                .frame(height: 1)
                        }
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.08)

                        // Section 2 — Add by User ID (manual)
                        addByUserIdSection
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.12)
                    } else {
                        // Non-App User creation form
                        createNonAppUserSection
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.04)
                    }
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("addVolunteer.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.done".localized) { dismiss() }
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) { hasAppeared = true }
            }
            .onChange(of: viewModel.error) { _, err in
                showError = err != nil
            }
            .alert("common.error".localized, isPresented: $showError) {
                Button("common.ok".localized) { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .alert(
                viewModel.addedVolunteerName.map { "\($0) Added!" } ?? "Volunteer Added!",
                isPresented: Binding(
                    get: { viewModel.addedVolunteerName != nil },
                    set: { if !$0 { viewModel.addedVolunteerName = nil } }
                )
            ) {
                Button("common.ok".localized) {
                    viewModel.addedVolunteerName = nil
                    userIdInput = ""
                    dismiss()
                }
            } message: {
                Text("The volunteer has been added to the department.")
            }
        }
    }

    // MARK: - Access Code Section

    private var accessCodeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("addVolunteer.accessCode.header".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text("addVolunteer.accessCode.title".localized)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("addVolunteer.accessCode.description".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            if let code = accessCode {
                Text(code)
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.l)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    )

                HStack(spacing: AppTheme.Spacing.m) {
                    Button {
                        UIPasteboard.general.string = code
                        HapticManager.shared.lightTap()
                        withAnimation(AppTheme.quickAnimation) { copiedCode = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(AppTheme.quickAnimation) { copiedCode = false }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: copiedCode ? "checkmark" : "doc.on.doc")
                            Text(copiedCode ? "common.copied".localized : "common.copy".localized)
                                .font(AppTheme.Typography.bodyMedium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.ButtonHeight.small)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                            .stroke(copiedCode ? AppTheme.StatusColors.accepted : AppTheme.themeColor, lineWidth: 1.5)
                    )
                    .foregroundStyle(copiedCode ? AppTheme.StatusColors.accepted : AppTheme.themeColor)
                    .animation(AppTheme.quickAnimation, value: copiedCode)

                    ShareLink(item: code, message: Text(String(format: "addVolunteer.accessCode.shareMessage".localized, code))) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text("common.share".localized)
                                .font(AppTheme.Typography.bodyMedium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.ButtonHeight.small)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                            .fill(AppTheme.themeColor)
                    )
                    .foregroundStyle(.white)
                }
            } else {
                Text("addVolunteer.accessCode.none".localized)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.l)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Add by User ID Section

    private var addByUserIdSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "person.badge.plus")
                    .foregroundStyle(AppTheme.themeColor)
                Text("addVolunteer.userId.header".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text("addVolunteer.userId.title".localized)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("addVolunteer.userId.description".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            HStack(spacing: AppTheme.Spacing.m) {
                TextField("addVolunteer.userId.placeholder".localized, text: $userIdInput)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.vertical, AppTheme.Spacing.m)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .strokeBorder(AppTheme.themeColor.opacity(0.3), lineWidth: 1)
                    )

                Button {
                    HapticManager.shared.lightTap()
                    Task {
                        await viewModel.addVolunteerByUserId(userId: userIdInput)
                    }
                } label: {
                    Group {
                        if viewModel.isAddingVolunteer {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.85)
                        } else {
                            Text("addVolunteer.userId.add".localized)
                                .font(AppTheme.Typography.bodyMedium)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppTheme.Spacing.l)
                    .frame(height: AppTheme.ButtonHeight.medium)
                }
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                        .fill(userIdInput.isEmpty || viewModel.isAddingVolunteer
                              ? AppTheme.themeColor.opacity(0.4)
                              : AppTheme.themeColor)
                )
                .disabled(userIdInput.isEmpty || viewModel.isAddingVolunteer)
            }

            Text("addVolunteer.userId.hint".localized)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Non-App User Section

    private var createNonAppUserSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "person.badge.plus")
                    .foregroundStyle(AppTheme.StatusColors.warning)
                Text("addVolunteer.nonApp.header".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text("addVolunteer.nonApp.title".localized)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("addVolunteer.nonApp.description".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            // Required fields
            nonAppField(label: "First Name", text: $nonAppFirstName, required: true)
            nonAppField(label: "Last Name", text: $nonAppLastName, required: true)

            // Congregation search (same component used across all forms)
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack(spacing: 4) {
                    Text("Congregation")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text("*")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.StatusColors.warning)
                }
                CongregationSearchField(
                    selectedName: $nonAppCongregationName,
                    selectedId: $nonAppCongregationId
                )
            }

            // Optional fields
            nonAppField(label: "Phone", text: $nonAppPhone, required: false)
                .keyboardType(.phonePad)

            // Appointment status
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Appointment")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                Picker("Appointment", selection: $nonAppAppointment) {
                    Text("Publisher").tag(AssemblyOpsAPI.AppointmentStatus.publisher)
                    Text("Ministerial Servant").tag(AssemblyOpsAPI.AppointmentStatus.ministerialServant)
                    Text("Elder").tag(AssemblyOpsAPI.AppointmentStatus.elder)
                }
                .pickerStyle(.segmented)
            }

            // Create button
            Button {
                HapticManager.shared.lightTap()
                Task {
                    await viewModel.createNonAppVolunteer(
                        firstName: nonAppFirstName,
                        lastName: nonAppLastName,
                        congregation: nonAppCongregationName,
                        phone: nonAppPhone.isEmpty ? nil : nonAppPhone,
                        email: nil,
                        appointmentStatus: .some(.case(nonAppAppointment))
                    )
                }
            } label: {
                Group {
                    if viewModel.isAddingVolunteer {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.85)
                    } else {
                        HStack(spacing: AppTheme.Spacing.s) {
                            Image(systemName: "person.badge.plus")
                            Text("addVolunteer.nonApp.create".localized)
                        }
                        .font(AppTheme.Typography.bodyMedium)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.ButtonHeight.medium)
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .fill(nonAppFormValid && !viewModel.isAddingVolunteer
                          ? AppTheme.StatusColors.warning
                          : AppTheme.StatusColors.warning.opacity(0.4))
            )
            .disabled(!nonAppFormValid || viewModel.isAddingVolunteer)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private var nonAppFormValid: Bool {
        !nonAppFirstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !nonAppLastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !nonAppCongregationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func nonAppField(label: String, text: Binding<String>, required: Bool) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack(spacing: 4) {
                Text(label)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                if required {
                    Text("*")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.StatusColors.warning)
                }
            }
            TextField(label, text: text)
                .font(AppTheme.Typography.body)
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.vertical, AppTheme.Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(AppTheme.cardBackgroundSecondary(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .strokeBorder(AppTheme.StatusColors.warning.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

#Preview {
    AddVolunteerSheet(viewModel: VolunteersViewModel())
}
