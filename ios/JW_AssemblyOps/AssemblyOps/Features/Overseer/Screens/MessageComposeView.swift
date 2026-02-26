//
//  MessageComposeView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/8/26.
//

// MARK: - Message Compose View
//
// Screen for composing and sending messages to volunteers, departments, or entire event.
// Supports single, multi-recipient, and template-based sends.
//
// Features:
//   - Segmented control for recipient type
//   - Single or multi-select volunteer picker
//   - Template picker for quick compose
//   - Subject and body fields
//   - Form validation
//
// Used by: OverseerMessagesView

import SwiftUI

struct MessageComposeView: View {
    let initialRecipientType: MessageRecipientType?

    @StateObject private var viewModel = MessageComposeViewModel()
    @ObservedObject private var sessionState: OverseerSessionState = .shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false
    @State private var showRecipientPicker = false
    @State private var showMultiRecipientPicker = false
    @State private var showTemplatePicker = false
    @State private var showError = false

    private let maxBodyLength = 5000

    init(initialRecipientType: MessageRecipientType? = nil) {
        self.initialRecipientType = initialRecipientType
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    recipientTypeCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    if viewModel.recipientType == .volunteer {
                        recipientCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                    }

                    messageCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

                    sendButton
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("messages.compose.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("general.cancel".localized) {
                        HapticManager.shared.lightTap()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showTemplatePicker = true
                        HapticManager.shared.lightTap()
                    } label: {
                        Image(systemName: "doc.text")
                    }
                }
            }
            .sheet(isPresented: $showRecipientPicker) {
                RecipientPickerSheet(
                    selectedVolunteerId: $viewModel.selectedVolunteerId,
                    selectedVolunteerName: $viewModel.selectedVolunteerName
                )
            }
            .sheet(isPresented: $showMultiRecipientPicker) {
                MultiRecipientPickerSheet(selectedIds: $viewModel.selectedVolunteerIds)
            }
            .sheet(isPresented: $showTemplatePicker) {
                MessageTemplateSheet { template in
                    viewModel.applyTemplate(template)
                }
            }
            .alert("messages.compose.sent".localized, isPresented: $viewModel.didSend) {
                Button("common.ok".localized) {
                    HapticManager.shared.lightTap()
                    dismiss()
                }
            } message: {
                Text(viewModel.sentCount == 1
                    ? "messages.compose.sent.single".localized
                    : String(format: "messages.compose.sent.multiple".localized, viewModel.sentCount))
            }
            .onChange(of: viewModel.error) { _, newValue in showError = newValue != nil }
            .alert("common.error".localized, isPresented: $showError) {
                Button("common.ok".localized) {
                    HapticManager.shared.lightTap()
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
            .onAppear {
                if let initialType = initialRecipientType {
                    viewModel.recipientType = initialType
                }

                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Recipient Type Card
    private var recipientTypeCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "person.2")
                    .foregroundStyle(AppTheme.themeColor)
                Text("messages.compose.recipientType".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Picker("messages.compose.recipientType".localized, selection: $viewModel.recipientType) {
                ForEach(availableRecipientTypes, id: \.self) { type in
                    Label(type.composeDisplayName, systemImage: type.composeIcon)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.recipientType) { _, newType in
                HapticManager.shared.lightTap()
                if newType != .volunteer {
                    viewModel.selectedVolunteerId = nil
                    viewModel.selectedVolunteerName = nil
                    viewModel.isMultiSelect = false
                    viewModel.selectedVolunteerIds.removeAll()
                }
            }

            Text(recipientTypeDescription)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private var availableRecipientTypes: [MessageRecipientType] {
        return [.volunteer, .department]
    }

    private var recipientTypeDescription: String {
        switch viewModel.recipientType {
        case .volunteer:
            return viewModel.isMultiSelect
                ? "messages.compose.multiSelect.description".localized
                : "messages.compose.volunteer.description".localized
        case .admin:
            return "messages.compose.admin.description".localized
        case .department:
            return String(format: "messages.compose.department.description".localized,
                          sessionState.selectedDepartment?.name ?? sessionState.claimedDepartment?.name ?? "messages.compose.yourDepartment".localized)
        case .event:
            return "messages.compose.event.description".localized
        }
    }

    // MARK: - Recipient Card
    private var recipientCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "person")
                    .foregroundStyle(AppTheme.themeColor)
                Text("messages.compose.recipient".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Multi-select toggle
            Toggle(isOn: $viewModel.isMultiSelect) {
                Label("messages.compose.multiSelect".localized, systemImage: "person.2.badge.gearshape")
                    .font(AppTheme.Typography.subheadline)
            }
            .tint(AppTheme.themeColor)
            .onChange(of: viewModel.isMultiSelect) { _, isMulti in
                HapticManager.shared.lightTap()
                if isMulti {
                    viewModel.selectedVolunteerId = nil
                    viewModel.selectedVolunteerName = nil
                } else {
                    viewModel.selectedVolunteerIds.removeAll()
                }
            }

            if viewModel.isMultiSelect {
                // Multi-select picker button
                Button {
                    HapticManager.shared.lightTap()
                    showMultiRecipientPicker = true
                } label: {
                    HStack {
                        if viewModel.selectedVolunteerIds.isEmpty {
                            Text("messages.compose.selectRecipients".localized)
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        } else {
                            Text(String(format: "messages.compose.selectedCount".localized, viewModel.selectedVolunteerIds.count))
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                }
            } else {
                // Single volunteer picker button
                Button {
                    HapticManager.shared.lightTap()
                    showRecipientPicker = true
                } label: {
                    HStack {
                        if let name = viewModel.selectedVolunteerName {
                            Text(name)
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(.primary)
                        } else {
                            Text("messages.compose.selectVolunteer".localized)
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Message Card
    private var messageCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "envelope")
                    .foregroundStyle(AppTheme.themeColor)
                Text("messages.compose.message".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Subject field
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("messages.compose.subject".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                TextField("", text: $viewModel.subject)
                    .textFieldStyle(.plain)
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
            }

            // Body field
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack {
                    Text("messages.compose.body".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Spacer()
                    Text("\(viewModel.body.count)/\(maxBodyLength)")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(viewModel.body.count > maxBodyLength
                            ? AppTheme.StatusColors.declined
                            : AppTheme.textTertiary(for: colorScheme))
                }

                TextEditor(text: $viewModel.body)
                    .frame(minHeight: 120)
                    .padding(AppTheme.Spacing.s)
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .stroke(AppTheme.textTertiary(for: colorScheme).opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Send Button
    private var sendButton: some View {
        Button {
            HapticManager.shared.lightTap()
            guard let eventId = sessionState.selectedEvent?.id else { return }
            let departmentId = sessionState.selectedDepartment?.id ?? sessionState.claimedDepartment?.id
            Task {
                await viewModel.send(eventId: eventId, departmentId: departmentId)
            }
        } label: {
            HStack(spacing: AppTheme.Spacing.s) {
                if viewModel.isSending {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("messages.compose.send".localized)
                }
            }
            .font(AppTheme.Typography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.l)
            .background(viewModel.isValid && viewModel.body.count <= maxBodyLength
                ? AppTheme.themeColor
                : AppTheme.textSecondary(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
        }
        .disabled(!viewModel.isValid || viewModel.isSending || viewModel.body.count > maxBodyLength)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        MessageComposeView()
    }
}
