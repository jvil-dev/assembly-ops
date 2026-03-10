//
//  VolunteerDetailView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Volunteer Detail View
//
// Detail screen showing complete volunteer information.
// Sections: Profile header, Department card, Contact card,
// Credentials card, Remove from Department button (editable only).
//

import SwiftUI

struct VolunteerDetailView: View {
    @State private var volunteer: VolunteerListItem
    let isEditable: Bool
    var onRemoved: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: VolunteerDetailViewModel
    @State private var showRemoveConfirmation = false
    @State private var showEditSheet = false
    @State private var showLinkSheet = false
    @State private var hasAppeared = false
    @State private var showCopiedToast = false
    @State private var linkUserIdInput = ""

    init(volunteer: VolunteerListItem, isEditable: Bool, onRemoved: (() -> Void)? = nil) {
        _volunteer = State(initialValue: volunteer)
        self.isEditable = isEditable
        self.onRemoved = onRemoved
        _viewModel = StateObject(wrappedValue: VolunteerDetailViewModel(volunteerId: volunteer.id))
    }

    var body: some View {
        ScrollView {
            contentView
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle(volunteer.firstName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear { onAppearAction() }
        .sheet(isPresented: $showEditSheet) { EditVolunteerSheet(volunteer: volunteer, viewModel: viewModel) }
        .confirmationDialog(
            "Remove from Department",
            isPresented: $showRemoveConfirmation,
            titleVisibility: .visible
        ) { removeDialogButtons } message: { removeDialogMessage }
        .onChange(of: viewModel.updateCount) { _, _ in
            if let updated = viewModel.updatedVolunteer {
                volunteer = updated
            }
        }
        .onChange(of: viewModel.didRemove) { _, didRemove in
            if didRemove { dismiss() }
        }
        .alert("common.error".localized, isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) { Button("common.ok".localized, role: .cancel) {} } message: { errorAlertMessage }
        .overlay(alignment: .bottom) { copiedToastOverlay }
    }

    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            if isEditable {
                Button("Edit") {
                    showEditSheet = true
                    HapticManager.shared.lightTap()
                }
                .fontWeight(.semibold)
            }
        }
    }

    private func onAppearAction() {
        withAnimation(AppTheme.entranceAnimation) {
            hasAppeared = true
        }
    }

    private var removeDialogButtons: some View {
        Group {
            Button("Remove", role: .destructive) {
                Task {
                    await viewModel.removeFromDepartment()
                    onRemoved?()
                    dismiss()
                }
            }
            Button("common.cancel".localized, role: .cancel) {}
        }
    }

    private var removeDialogMessage: some View {
        Text("Are you sure you want to remove \(volunteer.fullName) from your department?")
    }

    private var errorAlertMessage: some View {
        Group {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    private var copiedToastOverlay: some View {
        Group {
            if showCopiedToast {
                copiedToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var contentView: some View {
        mainContent
    }

    // Extracted to reduce type-checking complexity
    private var mainContent: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            profileHeader
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

            if volunteer.departmentName != nil {
                departmentCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
            }

            if volunteer.phone != nil || volunteer.email != nil {
                contactCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
            }

            credentialsCard
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)

            if volunteer.isPlaceholder && isEditable {
                linkToRealUserCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.175)
            }

            if isEditable {
                removeButton
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.2)
            }
        }
        .screenPadding()
        .padding(.top, AppTheme.Spacing.l)
        .padding(.bottom, AppTheme.Spacing.xxl)
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        Button {
            if isEditable {
                showEditSheet = true
                HapticManager.shared.lightTap()
            }
        } label: {
            VStack(spacing: AppTheme.Spacing.l) {
                // Avatar with initials (edit badge when editable)
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        Circle()
                            .fill(departmentColor.opacity(0.15))
                            .frame(width: 88, height: 88)

                        Circle()
                            .strokeBorder(departmentColor.opacity(0.3), lineWidth: 2)
                            .frame(width: 88, height: 88)

                        Text(volunteer.initials)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(departmentColor)
                    }

                    if isEditable {
                        Circle()
                            .fill(departmentColor)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "pencil")
                                    .font(AppTheme.Typography.captionSmall).fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            )
                            .offset(x: 2, y: 2)
                    }
                }

                VStack(spacing: AppTheme.Spacing.xs) {
                    Text(volunteer.fullName)
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(.primary)

                    Text(volunteer.congregation)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                    if volunteer.isPlaceholder {
                        Text("volunteer.badge.nonApp".localized)
                            .font(AppTheme.Typography.captionBold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.StatusColors.warning)
                            .clipShape(Capsule())
                    }

                    if let appointment = volunteer.appointmentStatus {
                        Text(formatAppointment(appointment))
                            .font(AppTheme.Typography.captionBold)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .cardPadding()
            .padding(.vertical, AppTheme.Spacing.s)
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
        .disabled(!isEditable)
    }

    // MARK: - Department Card

    private var departmentCard: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Department icon circle
            Circle()
                .fill(departmentColor)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: departmentIcon)
                        .foregroundStyle(.white)
                        .font(.system(size: 18, weight: .medium))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Department")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                if let department = volunteer.departmentName {
                    Text(department)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                }
            }

            Spacer()
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Contact Card

    private var contactCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Header
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "person.text.rectangle")
                    .foregroundStyle(AppTheme.themeColor)
                Text("Contact Info")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                if let phone = volunteer.phone, !phone.isEmpty {
                    infoRow(icon: "phone", text: phone)
                }

                if let email = volunteer.email, !email.isEmpty {
                    infoRow(icon: "envelope", text: email)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Identifier Card

    private var credentialsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "person.text.rectangle")
                    .foregroundStyle(AppTheme.themeColor)
                Text("User ID")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            HStack {
                Text(volunteer.userId ?? "—")
                    .font(.system(size: 17, design: .monospaced))
                    .foregroundStyle(.primary)
                Spacer()
                if let uid = volunteer.userId {
                    copyButton(text: uid)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Copy Button Helper

    private func copyButton(text: String) -> some View {
        Button {
            UIPasteboard.general.string = text
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
            Image(systemName: "doc.on.doc")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.themeColor)
                .frame(width: 40, height: 40)
                .background(AppTheme.themeColor.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Link to Real User Card

    private var linkToRealUserCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "person.badge.shield.checkmark")
                    .foregroundStyle(AppTheme.StatusColors.warning)
                Text("volunteerDetail.link.header".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text("volunteerDetail.link.title".localized)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("volunteerDetail.link.description".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            Button {
                showLinkSheet = true
                HapticManager.shared.lightTap()
            } label: {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "link")
                    Text("volunteerDetail.link.button".localized)
                }
                .font(AppTheme.Typography.headline)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.ButtonHeight.medium)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                        .fill(AppTheme.StatusColors.warning)
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .sheet(isPresented: $showLinkSheet) {
            linkSheet
        }
    }

    private var linkSheet: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.xl) {
                VStack(spacing: AppTheme.Spacing.m) {
                    Text("volunteerDetail.link.sheet.description".localized)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)

                    TextField("addVolunteer.userId.placeholder".localized, text: $linkUserIdInput)
                        .font(.system(size: 24, weight: .semibold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding()
                        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))

                    Text("volunteerDetail.link.sheet.hint".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                if viewModel.isLoading {
                    ProgressView()
                }

                Spacer()
            }
            .padding()
            .navigationTitle("volunteerDetail.link.sheet.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        showLinkSheet = false
                        linkUserIdInput = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("volunteerDetail.link.confirm".localized) {
                        guard let placeholderUserId = volunteer.userId else { return }
                        Task {
                            await viewModel.linkPlaceholderUser(
                                placeholderUserId: placeholderUserId,
                                realUserId: linkUserIdInput
                            )
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(linkUserIdInput.trimmingCharacters(in: .whitespacesAndNewlines).count < 6 || viewModel.isLoading)
                }
            }
        }
    }

    // MARK: - Remove Button

    private var removeButton: some View {
        Button {
            showRemoveConfirmation = true
        } label: {
            HStack(spacing: AppTheme.Spacing.s) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppTheme.StatusColors.declined)
                } else {
                    Image(systemName: "person.badge.minus")
                    Text("Remove from Department")
                }
            }
            .font(AppTheme.Typography.headline)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.ButtonHeight.medium)
            .foregroundStyle(AppTheme.StatusColors.declined)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .fill(AppTheme.StatusColors.declinedBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .strokeBorder(AppTheme.StatusColors.declined.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoading)
    }


    // MARK: - Copied Toast

    private var copiedToast: some View {
        HStack(spacing: AppTheme.Spacing.s) {
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

    // MARK: - Info Row Helper

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: icon)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                .frame(width: 16)
            Text(text)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
    }

    // MARK: - Helpers

    private var departmentColor: Color {
        if let type = volunteer.departmentType {
            return DepartmentColor.color(for: type)
        }
        return AppTheme.themeColor
    }

    private var departmentIcon: String {
        guard let type = volunteer.departmentType else { return "person" }
        return DepartmentColor.icon(for: type)
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

#Preview {
    NavigationStack {
        VolunteerDetailView(
            volunteer: VolunteerListItem(
                id: "1",
                userId: "A7X9K2",
                fullName: "John Smith",
                firstName: "John",
                lastName: "Smith",
                congregation: "Central Congregation",
                phone: "+1 (555) 123-4567",
                email: "john.smith@example.com",
                appointmentStatus: "ELDER",
                departmentId: "dept-1",
                departmentName: "Attendant",
                departmentType: "ATTENDANT",
                roleId: nil,
                roleName: nil,
                isPlaceholder: true
            ),
            isEditable: true
        )
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        VolunteerDetailView(
            volunteer: VolunteerListItem(
                id: "1",
                userId: "A7X9K2",
                fullName: "John Smith",
                firstName: "John",
                lastName: "Smith",
                congregation: "Central Congregation",
                phone: "+1 (555) 123-4567",
                email: "john.smith@example.com",
                appointmentStatus: "MINISTERIAL_SERVANT",
                departmentId: "dept-2",
                departmentName: "Parking",
                departmentType: "PARKING",
                roleId: nil,
                roleName: nil,
                isPlaceholder: false
            ),
            isEditable: false
        )
    }
    .preferredColorScheme(.dark)
}

