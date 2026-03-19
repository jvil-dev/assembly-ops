//
//  ConversationDetailView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

// MARK: - Conversation Detail View
//
// Chat-style thread view with message bubbles.
//
// Features:
//   - Chat bubble layout (sent right, received left)
//   - Sender name and timestamp on each bubble
//   - Reply input field at the bottom
//   - Auto-marks conversation as read
//   - Auto-scrolls to newest message
//   - Department accent color on sender bubbles
//   - Tap recipient name → profile sheet
//
// Used by: ConversationListView (navigation destination)

import SwiftUI

struct ConversationDetailView: View {
    @StateObject private var viewModel: ConversationDetailViewModel
    @ObservedObject private var sessionState: EventSessionState = .shared
    @Environment(\.colorScheme) var colorScheme
    @State private var replyText = ""
    @State private var hasAppeared = false
    @State private var showProfile = false
    @FocusState private var isReplyFocused: Bool

    let otherParticipantName: String
    let otherParticipantPhone: String?
    let otherParticipantCongregation: String?
    let isBroadcast: Bool

    private var accentColor: Color {
        if let deptType = sessionState.selectedDepartment?.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    init(conversationId: String, otherParticipantName: String, otherParticipantPhone: String? = nil, otherParticipantCongregation: String? = nil, currentUserId: String?, isBroadcast: Bool = false) {
        self.otherParticipantName = otherParticipantName
        self.otherParticipantPhone = otherParticipantPhone
        self.otherParticipantCongregation = otherParticipantCongregation
        self.isBroadcast = isBroadcast
        _viewModel = StateObject(wrappedValue: ConversationDetailViewModel(
            conversationId: conversationId,
            currentUserId: currentUserId
        ))
    }

#Preview {
    ConversationDetailView(
        conversationId: "conv-1",
        otherParticipantName: "John Smith",
        otherParticipantPhone: "555-0123",
        otherParticipantCongregation: "North Valley",
        currentUserId: "user-1"
    )
}

    var body: some View {
        VStack(spacing: 0) {
            // Messages area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.s) {
                        ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: viewModel.isFromCurrentUser(message),
                                accentColor: accentColor,
                                colorScheme: colorScheme
                            )
                            .id(message.id)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.02)
                        }
                    }
                    .screenPadding()
                    .padding(.top, AppTheme.Spacing.m)
                    .padding(.bottom, AppTheme.Spacing.m)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            if !isBroadcast {
                Divider()

                // Reply input
                replyBar
            }
        }
        .themedBackground(scheme: colorScheme)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if isBroadcast {
                    Text(otherParticipantName)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                } else {
                    Button {
                        showProfile = true
                        HapticManager.shared.lightTap()
                    } label: {
                        Text(otherParticipantName)
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(.primary)
                    }
                    .accessibilityHint(NSLocalizedString("messages.a11y.viewProfile", comment: ""))
                }
            }
        }
        .task {
            if !viewModel.hasLoaded {
                await viewModel.fetchMessages()
                await viewModel.markAsRead()
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
            viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
        .sheet(isPresented: $showProfile) {
            profileSheet
        }
    }

    // MARK: - Reply Bar

    private var replyBar: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            TextField("messages.conversation.reply.placeholder".localized, text: $replyText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .focused($isReplyFocused)
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.vertical, AppTheme.Spacing.s)
                .background(AppTheme.cardBackground(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(AppTheme.dividerColor(for: colorScheme), lineWidth: 1)
                )

            Button {
                let text = replyText
                replyText = ""
                Task {
                    await viewModel.sendReply(body: text)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? accentColor : AppTheme.textTertiary(for: colorScheme))
            }
            .disabled(!canSend || viewModel.isSending)
            .accessibilityLabel(NSLocalizedString("messages.a11y.send", comment: ""))
        }
        .padding(.horizontal, AppTheme.Spacing.screenEdge)
        .padding(.vertical, AppTheme.Spacing.s)
        .background(AppTheme.cardBackground(for: colorScheme))
    }

    private var canSend: Bool {
        !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Profile Sheet

    private var profileSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Avatar + Name
                    VStack(spacing: AppTheme.Spacing.m) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(accentColor.opacity(0.7))

                        Text(otherParticipantName)
                            .font(AppTheme.Typography.title)
                            .foregroundStyle(.primary)
                    }
                    .padding(.top, AppTheme.Spacing.l)

                    // Info card
                    VStack(spacing: 0) {
                        // Congregation row
                        HStack(spacing: AppTheme.Spacing.m) {
                            Image(systemName: "building.2")
                                .font(.system(size: 18))
                                .foregroundStyle(accentColor)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("messages.profile.congregation".localized)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                                Text(otherParticipantCongregation ?? "messages.profile.noCongregation".localized)
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(otherParticipantCongregation != nil ? .primary : AppTheme.textTertiary(for: colorScheme))
                            }

                            Spacer()
                        }
                        .padding(AppTheme.Spacing.cardPadding)

                        Divider()
                            .padding(.leading, AppTheme.Spacing.cardPadding + 28 + AppTheme.Spacing.m)

                        // Phone row
                        if let phone = otherParticipantPhone {
                            Link(destination: URL(string: "tel:\(phone)")!) {
                                HStack(spacing: AppTheme.Spacing.m) {
                                    Image(systemName: "phone")
                                        .font(.system(size: 18))
                                        .foregroundStyle(accentColor)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("messages.profile.phone".localized)
                                            .font(AppTheme.Typography.caption)
                                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                                        Text(phone)
                                            .font(AppTheme.Typography.body)
                                            .foregroundStyle(accentColor)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                                }
                            }
                            .padding(AppTheme.Spacing.cardPadding)
                        } else {
                            HStack(spacing: AppTheme.Spacing.m) {
                                Image(systemName: "phone")
                                    .font(.system(size: 18))
                                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("messages.profile.phone".localized)
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                                    Text("messages.profile.noPhone".localized)
                                        .font(AppTheme.Typography.body)
                                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                                }

                                Spacer()
                            }
                            .padding(AppTheme.Spacing.cardPadding)
                        }
                    }
                    .themedCard(scheme: colorScheme)
                }
                .screenPadding()
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("messages.profile.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("general.cancel".localized) {
                        showProfile = false
                    }
                }
            }
        }
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    let accentColor: Color
    let colorScheme: ColorScheme

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 50) }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: AppTheme.Spacing.xs) {
                // Sender name (only for received messages)
                if !isFromCurrentUser, let name = message.senderName {
                    Text(name)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                // Bubble
                Text(message.body)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(isFromCurrentUser ? .white : .primary)
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.vertical, AppTheme.Spacing.s)
                    .background(isFromCurrentUser ? accentColor : AppTheme.cardBackground(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)

                // Timestamp
                Text(message.formattedDate)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            if !isFromCurrentUser { Spacer(minLength: 50) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(bubbleAccessibilityLabel)
    }

    private var bubbleAccessibilityLabel: String {
        let sender = isFromCurrentUser ? "You" : (message.senderName ?? "Unknown")
        return "\(sender): \(message.body), \(message.formattedDate)"
    }
}
