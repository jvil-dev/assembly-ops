//
//  MessageComposeView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/8/26.
//

// MARK: - Message Compose View
//
// Screen for composing and sending messages to volunteers, departments, or entire event.
// Supports three recipient types with appropriate picker UI for each.
//
// Parameters:
//   - initialRecipientType: Optional pre-selected recipient type (volunteer/department/event)
//
// Features:
//   - Segmented control for recipient type selection
//   - Volunteer picker for individual messages
//   - Optional subject field (shown for volunteers)
//   - Required message body field
//   - Form validation
//   - Success/error handling with alerts
//
// Recipient Types:
//   - Volunteer: Sends to individual volunteer (requires selection)
//   - Department: Broadcasts to all volunteers in current department
//   - Event: Broadcasts to all volunteers across entire event
//
// Navigation:
//   - Accessed from OverseerMessagesView via compose button
//   - Dismisses after successful send

import SwiftUI

struct MessageComposeView: View {
    let initialRecipientType: MessageRecipientType?

    @StateObject private var viewModel = MessageComposeViewModel()
    @ObservedObject private var sessionState: OverseerSessionState = .shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false
    @State private var showRecipientPicker = false

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
            .navigationTitle("Compose Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.shared.lightTap()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showRecipientPicker) {
                RecipientPickerSheet(
                    selectedVolunteerId: $viewModel.selectedVolunteerId,
                    selectedVolunteerName: $viewModel.selectedVolunteerName
                )
            }
            .alert("Message Sent", isPresented: $viewModel.didSend) {
                Button("OK") {
                    HapticManager.shared.lightTap()
                    dismiss()
                }
            } message: {
                Text(viewModel.sentCount == 1
                    ? "Message sent successfully."
                    : "Message sent to \(viewModel.sentCount) volunteers.")
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    HapticManager.shared.lightTap()
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
            .onAppear {
                // Set initial recipient type if provided
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
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "person.2")
                    .foregroundStyle(AppTheme.themeColor)
                Text("RECIPIENT TYPE")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Picker - only show Event option if user is App Admin
            Picker("Recipient Type", selection: $viewModel.recipientType) {
                ForEach(availableRecipientTypes, id: \.self) { type in
                    Label(type.composeDisplayName, systemImage: type.composeIcon)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.recipientType) { _, newType in
                HapticManager.shared.lightTap()
                // Clear volunteer selection when switching away from volunteer type
                if newType != .volunteer {
                    viewModel.selectedVolunteerId = nil
                    viewModel.selectedVolunteerName = nil
                }
            }

            // Description text
            Text(recipientTypeDescription)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private var availableRecipientTypes: [MessageRecipientType] {
        if sessionState.isEventOverseer {
            return MessageRecipientType.allCases
        } else {
            return [.volunteer, .department]
        }
    }

    private var recipientTypeDescription: String {
        switch viewModel.recipientType {
        case .volunteer:
            return "Send a message to one specific volunteer"
        case .department:
            return "Send to all volunteers in \(sessionState.selectedDepartment?.name ?? "your department")"
        case .event:
            return "Send to all volunteers across the entire event"
        }
    }

    // MARK: - Recipient Card (Individual Volunteer)
    private var recipientCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "person")
                    .foregroundStyle(AppTheme.themeColor)
                Text("RECIPIENT")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Volunteer selection button
            Button {
                HapticManager.shared.lightTap()
                showRecipientPicker = true
            } label: {
                HStack {
                    if let name = viewModel.selectedVolunteerName {
                        Text(name)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(Color.primary)
                    } else {
                        Text("Select Volunteer")
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
                .cornerRadius(AppTheme.CornerRadius.small)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Message Card
    private var messageCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "envelope")
                    .foregroundStyle(AppTheme.themeColor)
                Text("MESSAGE")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Subject field
            VStack(alignment: .leading, spacing: 4) {
                Text("Subject (optional)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                TextField("Enter subject...", text: $viewModel.subject)
                    .textFieldStyle(.plain)
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .cornerRadius(AppTheme.CornerRadius.small)
            }

            // Body field
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Message *")
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
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .cornerRadius(AppTheme.CornerRadius.small)
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
                    Text("Send Message")
                }
            }
            .font(AppTheme.Typography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.l)
            .background(viewModel.isValid && viewModel.body.count <= maxBodyLength
                ? AppTheme.themeColor
                : AppTheme.textSecondary(for: colorScheme))
            .cornerRadius(AppTheme.CornerRadius.button)
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
