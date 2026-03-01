//
//  VolunteerDetailView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Volunteer Detail View
//
// Detail screen showing complete volunteer information.
// Uses the app's design system with warm background and floating cards.
//
// Parameters:
//   - volunteer: VolunteerListItem containing all volunteer data
//   - isEditable: Whether this volunteer can be modified (department-scoped)
//   - onRemoved: Callback when volunteer is removed from department
//
// Sections:
//   - Profile header: Avatar with initials, name, congregation, appointment
//   - Department card: Department name with color indicator
//   - Contact card: Phone and email details
//   - Credentials card: Volunteer ID with copy button
//   - Remove button (editable only): Delete volunteer from department
//
// Features:
//   - Warm gradient background
//   - Floating cards with layered shadows
//   - Staggered entrance animations
//   - Conditional editing based on isEditable flag
//   - Confirmation dialog before removal
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
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false
    @State private var hasAppeared = false
    @State private var showCopiedToast = false

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
        .confirmationDialog(
            "Delete Volunteer",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) { deleteDialogButtons } message: { deleteDialogMessage }
        .onChange(of: viewModel.updateCount) { _, _ in
            if let updated = viewModel.updatedVolunteer {
                volunteer = updated
            }
        }
        .onChange(of: viewModel.didDelete) { _, didDelete in
            if didDelete { dismiss() }
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
        if isEditable {
            Task { await viewModel.loadAssignments() }
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

    private var deleteDialogButtons: some View {
        Group {
            Button("Delete Permanently", role: .destructive) {
                Task { await viewModel.deleteVolunteer() }
            }
            Button("common.cancel".localized, role: .cancel) {}
        }
    }

    private var deleteDialogMessage: some View {
        Text("Are you sure you want to permanently delete \(volunteer.fullName)? This will remove all their assignments and check-in records. This action cannot be undone.")
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

            if isEditable && !viewModel.assignments.isEmpty {
                assignmentsCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.08)
            }

            if volunteer.phone != nil || volunteer.email != nil {
                contactCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
            }

            credentialsCard
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)

            if isEditable {
                VStack(spacing: AppTheme.Spacing.m) {
                    removeButton
                    deleteButton
                }
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

            // Role badge if assigned
            if let role = volunteer.roleName {
                Text(role)
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(departmentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(departmentColor.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Assignments Card

    private var assignmentsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "calendar.badge.checkmark")
                    .foregroundStyle(AppTheme.themeColor)
                Text("Assignments")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            if viewModel.isLoadingAssignments {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                ForEach(Array(viewModel.assignments.enumerated()), id: \.element.id) { index, assignment in
                    if index > 0 { Divider() }

                    if isAVDepartment {
                        // AV departments: read-only row (no captain toggle)
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(assignment.sessionName)
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundStyle(.primary)
                            Text(assignment.postName)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        }
                    } else {
                        // Non-AV departments: captain toggle
                        Toggle(isOn: Binding(
                            get: { assignment.isCaptain },
                            set: { newValue in
                                Task { await viewModel.setCaptain(assignmentId: assignment.id, isCaptain: newValue) }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                HStack(spacing: AppTheme.Spacing.xs) {
                                    Text(assignment.sessionName)
                                        .font(AppTheme.Typography.bodyMedium)
                                        .foregroundStyle(.primary)
                                    if assignment.isCaptain {
                                        Image(systemName: "star.fill")
                                            .font(AppTheme.Typography.captionSmall)
                                            .foregroundStyle(AppTheme.themeColor)
                                    }
                                }
                                Text(assignment.postName)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                            }
                        }
                        .tint(AppTheme.themeColor)
                        .disabled(assignment.status == "DECLINED" || assignment.status == "AUTO_DECLINED")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack(spacing: AppTheme.Spacing.s) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppTheme.StatusColors.declined)
                } else {
                    Image(systemName: "trash")
                    Text("Delete Volunteer")
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

    private var isAVDepartment: Bool {
        ["AUDIO", "VIDEO", "STAGE"].contains(volunteer.departmentType?.uppercased() ?? "")
    }

    private var departmentColor: Color {
        if let type = volunteer.departmentType {
            return DepartmentColor.color(for: type)
        }
        return AppTheme.themeColor
    }

    private var departmentIcon: String {
        guard let type = volunteer.departmentType else { return "person" }

        switch type.uppercased() {
        case "PARKING": return "car"
        case "ATTENDANT": return "person.badge.shield.checkmark"
        case "AUDIO": return "speaker.wave.3"
        case "VIDEO": return "video"
        case "STAGE": return "light.overhead.left"
        case "CLEANING": return "sparkles"
        case "COMMITTEE": return "person.3"
        case "FIRST_AID", "FIRSTAID": return "cross"
        case "BAPTISM": return "drop"
        case "INFORMATION", "INFORMATION_VOLUNTEER_SERVICE": return "info.circle"
        case "ACCOUNTS": return "dollarsign.circle"
        case "INSTALLATION": return "hammer"
        case "LOST_FOUND", "LOST_AND_FOUND", "LOST_FOUND_CHECKROOM": return "tray"
        case "ROOMING": return "bed.double"
        case "TRUCKING", "TRUCKING_EQUIPMENT": return "truck.box"
        default: return "person"
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
                roleName: "Captain"
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
                roleName: nil
            ),
            isEditable: false
        )
    }
    .preferredColorScheme(.dark)
}

