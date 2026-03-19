//
//  MessageComposeView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/8/26.
//

// MARK: - Message Compose View (Announcement)
//
// Screen for composing announcements to departments or entire event.
// Individual messaging goes through the conversation flow (ComposeMessageView).
//
// Features:
//   - Segmented control for recipient type (department / broadcast)
//   - Template picker for quick compose
//   - Subject and body fields
//   - Form validation
//
// Used by: MessagesView (overseer announcement button)

import SwiftUI

struct MessageComposeView: View {
    let initialRecipientType: MessageRecipientType?

    @StateObject private var viewModel = MessageComposeViewModel()
    @ObservedObject private var sessionState: EventSessionState = .shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false
    @State private var showTemplatePicker = false
    @State private var showError = false

    private let maxBodyLength = 5000

    private var accentColor: Color {
        if let deptType = sessionState.selectedDepartment?.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    init(initialRecipientType: MessageRecipientType? = nil) {
        self.initialRecipientType = initialRecipientType
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    recipientTypeCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    messageCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    sendButton
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("messages.announcement.title".localized)
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
                    .foregroundStyle(accentColor)
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
            .onChange(of: viewModel.recipientType) { _, _ in
                HapticManager.shared.lightTap()
            }

            Text(recipientTypeDescription)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private var availableRecipientTypes: [MessageRecipientType] {
        return [.department, .event]
    }

    private var recipientTypeDescription: String {
        switch viewModel.recipientType {
        case .volunteer, .user:
            return ""
        case .department:
            return String(format: "messages.compose.department.description".localized,
                          sessionState.selectedDepartment?.name ?? sessionState.claimedDepartment?.name ?? "messages.compose.yourDepartment".localized)
        case .event:
            return "messages.compose.event.description".localized
        }
    }

    // MARK: - Message Card
    private var messageCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "envelope")
                    .foregroundStyle(accentColor)
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
                ? accentColor
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
