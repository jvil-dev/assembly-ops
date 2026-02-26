//
//  ComposeMessageView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

// MARK: - Compose Message View
//
// Shared compose view for sending messages (used by both volunteers and overseers).
// For volunteers: sends to overseers or other volunteers via startConversation.
// For overseers: uses the existing MessageComposeView flow.
//
// Used by: MessagesView (volunteer compose)

import SwiftUI

struct ComposeMessageView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false

    @State private var recipientName: String = ""
    @State private var subject: String = ""
    @State private var messageBody: String = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var showError = false

    let eventId: String
    let currentUserId: String?
    let onSent: ((Conversation) -> Void)?

    /// Available recipients — passed from the parent view
    let recipients: [RecipientOption]

    @State private var selectedRecipient: RecipientOption?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    recipientCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    subjectCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    bodyCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
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
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await send() }
                    } label: {
                        if isSending {
                            ProgressView()
                        } else {
                            Text("messages.compose.send".localized)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isValid || isSending)
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
            .onChange(of: errorMessage) { _, newValue in
                showError = newValue != nil
            }
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

            if recipients.isEmpty {
                Text("messages.compose.noRecipients".localized)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            } else {
                Menu {
                    ForEach(recipients) { recipient in
                        Button {
                            selectedRecipient = recipient
                            HapticManager.shared.lightTap()
                        } label: {
                            Label(recipient.displayName, systemImage: recipient.isAdmin ? "person.badge.shield.checkmark" : "person")
                        }
                    }
                } label: {
                    HStack {
                        if let selected = selectedRecipient {
                            Label(selected.displayName, systemImage: selected.isAdmin ? "person.badge.shield.checkmark" : "person")
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(.primary)
                        } else {
                            Text("messages.compose.selectRecipient".localized)
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        }

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
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Subject Card

    private var subjectCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "text.cursor")
                    .foregroundStyle(AppTheme.themeColor)
                Text("messages.compose.subject".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            TextField("messages.compose.subject.placeholder".localized, text: $subject)
                .textFieldStyle(.plain)
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Body Card

    private var bodyCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "text.alignleft")
                    .foregroundStyle(AppTheme.themeColor)
                Text("messages.compose.body".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            TextEditor(text: $messageBody)
                .frame(minHeight: 120)
                .padding(AppTheme.Spacing.s)
                .scrollContentBackground(.hidden)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Logic

    private var isValid: Bool {
        selectedRecipient != nil &&
        !messageBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() async {
        guard let recipient = selectedRecipient else { return }
        isSending = true
        defer { isSending = false }

        let subjectText = subject.isEmpty ? nil : subject
        let bodyText = messageBody.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let recipientType: AssemblyOpsAPI.MessageSenderType = recipient.isAdmin ? .user : .volunteer
            let conversation = try await MessagesService.shared.startConversation(
                eventId: eventId,
                recipientType: recipientType,
                recipientId: recipient.id,
                subject: subjectText,
                body: bodyText,
                currentUserId: currentUserId
            )
            HapticManager.shared.success()
            onSent?(conversation)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
    }
}

// MARK: - Recipient Option

struct RecipientOption: Identifiable, Hashable {
    let id: String
    let displayName: String
    let isAdmin: Bool
}
