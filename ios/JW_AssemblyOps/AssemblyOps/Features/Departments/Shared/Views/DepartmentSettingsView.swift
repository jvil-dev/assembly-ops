//
//  DepartmentSettingsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/25/26.
//

// MARK: - Department Settings View
//
// Displays full department configuration for a department overseer:
//   1. Event Info card — name, type, dates, venue
//   2. Access Code card — large monospaced code + copy + share
//   3. Department Roster — overseer (locked) + assistant overseers (assignable)
//   4. Privacy Toggle — public/private department visibility
//   5. Event Status — days remaining or archived
//
// Pushed from GenericDepartmentView or AttendantDashboardView.

import SwiftUI
import Apollo

struct DepartmentSettingsView: View {
    let departmentId: String

    @StateObject private var viewModel = DepartmentSettingsViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showError = false
    @State private var copiedCode = false
    @State private var showAssignSheet = false
    @State private var showRemoveConfirm = false
    @State private var removeTarget: DepartmentSettingsViewModel.HierarchyRoleItem?
    @State private var showSuccessBanner = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let dept = viewModel.departmentInfo {
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        eventInfoCard(dept)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                        accessCodeCard(dept)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                        rosterCard(dept)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

                        privacyCard(dept)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)

                        eventStatusCard(dept)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.2)
                    }
                    .screenPadding()
                    .padding(.top, AppTheme.Spacing.l)
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }
                .refreshable {
                    await viewModel.reload(departmentId: departmentId)
                }
            } else {
                VStack(spacing: AppTheme.Spacing.m) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text("deptSettings.loadFailed".localized)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Button("Retry") {
                        viewModel.load(departmentId: departmentId)
                    }
                    .foregroundStyle(AppTheme.themeColor)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("deptSettings.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) { hasAppeared = true }
            viewModel.load(departmentId: departmentId)
        }
        .onChange(of: viewModel.errorMessage) { _, error in
            showError = error != nil
        }
        .onChange(of: viewModel.successMessage) { _, message in
            guard message != nil else { return }
            withAnimation(AppTheme.quickAnimation) { showSuccessBanner = true }
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                withAnimation(AppTheme.quickAnimation) { showSuccessBanner = false }
                viewModel.successMessage = nil
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .overlay(alignment: .top) {
            if showSuccessBanner, let msg = viewModel.successMessage {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                    Text(msg)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, AppTheme.Spacing.l)
                .padding(.vertical, AppTheme.Spacing.m)
                .background(AppTheme.StatusColors.accepted)
                .clipShape(Capsule())
                .shadow(color: AppTheme.StatusColors.accepted.opacity(0.3), radius: 8, x: 0, y: 4)
                .padding(.top, AppTheme.Spacing.m)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .confirmationDialog(
            "deptSettings.roster.removeConfirm".localized,
            isPresented: $showRemoveConfirm,
            titleVisibility: .visible
        ) {
            Button("deptSettings.roster.removeAction".localized, role: .destructive) {
                if let target = removeTarget {
                    viewModel.removeAssistantOverseer(eventVolunteerId: target.eventVolunteerId)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Event Info Card

    private func eventInfoCard(_ dept: DepartmentSettingsViewModel.DepartmentDetail) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(AppTheme.themeColor)
                Text("deptSettings.eventInfo".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text(dept.eventName)
                .font(AppTheme.Typography.title)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                infoRow(icon: "building.2", text: dept.name)
                infoRow(icon: "tag", text: displayEventType(dept.eventType))
                infoRow(icon: "mappin.circle.fill", text: dept.venue)
                infoRow(icon: "calendar", text: formatDateRange(dept.startDate, dept.endDate))
                infoRow(icon: "person.2.fill", text: String(format: "deptSettings.volunteerCount".localized, dept.volunteerCount))
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Access Code Card

    private func accessCodeCard(_ dept: DepartmentSettingsViewModel.DepartmentDetail) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("deptSettings.accessCode".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text("deptSettings.accessCode.subtitle".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            if let code = dept.accessCode {
                // Large code display
                Text(code)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.l)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    )

                // Copy + Share row
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
                            Text(copiedCode ? "deptSettings.accessCode.copied".localized : "deptSettings.accessCode.copy".localized)
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

                    ShareLink(item: code, message: Text(String(format: "deptSettings.accessCode.shareMessage".localized, dept.name, code))) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text("deptSettings.accessCode.share".localized)
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
                Text("deptSettings.accessCode.none".localized)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Roster Card

    private func rosterCard(_ dept: DepartmentSettingsViewModel.DepartmentDetail) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("deptSettings.roster".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Department Overseer (locked)
            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.themeColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(dept.overseerName ?? "—")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(.primary)
                    Text("deptSettings.roster.overseer".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.themeColor)
                }

                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
            .padding(AppTheme.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.1 : 0.04))
            )

            // Assistant Overseers
            ForEach(dept.hierarchyRoles) { role in
                HStack(spacing: AppTheme.Spacing.m) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(colorScheme == .dark ? 0.2 : 0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "person.badge.key")
                            .font(.system(size: 16))
                            .foregroundStyle(.orange)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(role.volunteerName)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundStyle(.primary)
                        Text("deptSettings.roster.assistant".localized)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.orange)
                    }

                    Spacer()

                    Button {
                        removeTarget = role
                        showRemoveConfirm = true
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(AppTheme.StatusColors.declined)
                    }
                }
                .padding(AppTheme.Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(AppTheme.cardBackgroundSecondary(for: colorScheme))
                )
            }

            // Add Assistant button
            Button {
                showAssignSheet = true
            } label: {
                HStack(spacing: AppTheme.Spacing.s) {
                    if viewModel.isAssigningRole {
                        ProgressView().scaleEffect(0.8).tint(AppTheme.themeColor)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppTheme.themeColor)
                    }
                    Text("deptSettings.roster.addAssistant".localized)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(AppTheme.themeColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.ButtonHeight.medium)
            }
            .disabled(viewModel.isAssigningRole)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .strokeBorder(AppTheme.themeColor.opacity(viewModel.isAssigningRole ? 0.2 : 0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            )
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .sheet(isPresented: $showAssignSheet) {
            AssistantOverseerPickerSheet(
                onAssign: { eventVolunteerId in
                    viewModel.assignAssistantOverseer(eventVolunteerId: eventVolunteerId)
                    showAssignSheet = false
                }
            )
        }
    }

    // MARK: - Privacy Card

    private func privacyCard(_ dept: DepartmentSettingsViewModel.DepartmentDetail) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "eye.slash")
                    .foregroundStyle(AppTheme.themeColor)
                Text("deptSettings.privacy".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Toggle(isOn: Binding(
                get: { dept.isPublic },
                set: { viewModel.setPrivacy(isPublic: $0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("deptSettings.privacy.toggle".localized)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(.primary)
                    Text("deptSettings.privacy.description".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
            }
            .tint(AppTheme.themeColor)
            .disabled(viewModel.isSavingPrivacy)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Event Status Card

    private func eventStatusCard(_ dept: DepartmentSettingsViewModel.DepartmentDetail) -> some View {
        let startDate = DateUtils.parseISO8601(dept.startDate)
        let endDate = DateUtils.parseISO8601(dept.endDate)
        let now = Date()

        let statusInfo: (icon: String, text: String, color: Color) = {
            if let end = endDate, now > end {
                return ("checkmark.circle.fill", "deptSettings.status.completed".localized, AppTheme.StatusColors.accepted)
            } else if let start = startDate, now < start {
                let days = Calendar.current.dateComponents([.day], from: now, to: start).day ?? 0
                return ("clock.fill", String(format: "deptSettings.status.upcoming".localized, days), AppTheme.themeColor)
            } else {
                return ("bolt.fill", "deptSettings.status.active".localized, .green)
            }
        }()

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("deptSettings.status".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(statusInfo.color.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: statusInfo.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(statusInfo.color)
                }

                Text(statusInfo.text)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundStyle(.primary)

                Spacer()
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Helpers

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.themeColor.opacity(0.7))
                .frame(width: 18)
            Text(text)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
    }

    private func displayEventType(_ raw: String) -> String {
        switch raw {
        case "CIRCUIT_ASSEMBLY_CO", "CIRCUIT_ASSEMBLY_BR": return "Circuit Assembly"
        case "REGIONAL_CONVENTION": return "Regional Convention"
        case "SPECIAL_CONVENTION": return "Special Convention"
        default: return raw
        }
    }

    private func formatDateRange(_ start: String, _ end: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, yyyy"
        let startStr = DateUtils.parseISO8601(start).map { fmt.string(from: $0) } ?? start
        let endStr = DateUtils.parseISO8601(end).map { fmt.string(from: $0) } ?? end
        return "\(startStr) – \(endStr)"
    }
}

// MARK: - Assistant Overseer Picker Sheet

struct AssistantOverseerPickerSheet: View {
    let onAssign: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var volunteerId = ""
    @FocusState private var isFieldFocused: Bool

    private var isValid: Bool {
        !volunteerId.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Instruction card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        HStack(spacing: AppTheme.Spacing.s) {
                            Image(systemName: "person.badge.key")
                                .foregroundStyle(AppTheme.themeColor)
                            Text("deptSettings.picker.instructions.title".localized)
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(.primary)
                        }

                        Text("deptSettings.picker.instructions.body".localized)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                        UnderlineTextField(
                            label: "deptSettings.picker.idLabel".localized,
                            placeholder: "deptSettings.picker.idPlaceholder".localized,
                            text: $volunteerId,
                            isSecure: false,
                            isFocused: isFieldFocused,
                            onSubmit: { if isValid { assign() } },
                            autocapitalization: .never,
                            keyboardType: .default,
                            isMonospaced: true
                        )
                        .focused($isFieldFocused)
                        .padding(.top, AppTheme.Spacing.s)
                    }
                    .cardPadding()
                    .themedCard(scheme: colorScheme)

                    // Assign button
                    Button {
                        assign()
                    } label: {
                        Text("deptSettings.picker.assign".localized)
                            .font(AppTheme.Typography.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppTheme.ButtonHeight.medium)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                            .fill(isValid ? AppTheme.themeColor : AppTheme.themeColor.opacity(0.4))
                    )
                    .foregroundStyle(.white)
                    .disabled(!isValid)
                    .animation(AppTheme.quickAnimation, value: isValid)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("deptSettings.picker.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
            }
            .onAppear { isFieldFocused = true }
        }
    }

    private func assign() {
        let trimmed = volunteerId.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onAssign(trimmed)
    }
}

