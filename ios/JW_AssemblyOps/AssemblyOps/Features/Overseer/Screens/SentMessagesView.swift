//
//  SentMessagesView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/8/26.
//

import SwiftUI

struct SentMessagesView: View {
    @StateObject private var viewModel = SentMessagesViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            // Background
            AppTheme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            if viewModel.isLoading && !viewModel.hasLoaded {
                LoadingView(message: "Loading messages...")
            } else if viewModel.isEmpty {
                emptyState
            } else {
                messagesList
            }
        }
        .navigationTitle("Sent Messages")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            if !viewModel.hasLoaded {
                await viewModel.fetchMessages()
            }
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
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Spacer()

            Image(systemName: "envelope")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Text("No Messages Sent")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("Messages you send will appear here")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppTheme.Spacing.screenEdge)
        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.m) {
                ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                    SentMessageRow(message: message, colorScheme: colorScheme)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.03)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.s)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }
}

// MARK: - Sent Message Row

private struct SentMessageRow: View {
    let message: SentMessageItem
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Header row: recipient type badge + timestamp
            HStack {
                // Recipient type badge
                HStack(spacing: 4) {
                    Image(systemName: recipientIcon)
                        .font(.caption)
                    Text(message.recipientTypeDisplayName)
                        .font(AppTheme.Typography.caption)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, AppTheme.Spacing.s)
                .padding(.vertical, 4)
                .background(recipientColor)
                .cornerRadius(AppTheme.CornerRadius.small)

                Spacer()

                // Timestamp
                Text(timeAgo)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Recipient name (if individual)
            if let recipientName = message.recipientName {
                HStack(spacing: 6) {
                    Image(systemName: "person.circle.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Text(recipientName)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
            }

            // Subject (if present)
            if let subject = message.subject, !subject.isEmpty {
                Text(subject)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
            }

            // Body preview (first 2 lines)
            Text(message.body)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .lineLimit(2)

            // Read status indicator (for individual messages)
            if message.recipientType == "VOLUNTEER" {
                HStack(spacing: 4) {
                    Image(systemName: message.isRead ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundStyle(message.isRead ? AppTheme.StatusColors.accepted : AppTheme.textTertiary(for: colorScheme))
                    Text(message.isRead ? "Read" : "Unread")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private var recipientIcon: String {
        switch message.recipientType {
        case "VOLUNTEER": return "person"
        case "DEPARTMENT": return "person.3"
        case "EVENT": return "megaphone"
        default: return "envelope"
        }
    }

    private var recipientColor: Color {
        switch message.recipientType {
        case "VOLUNTEER": return AppTheme.themeColor
        case "DEPARTMENT": return .blue
        case "EVENT": return .purple
        default: return .gray
        }
    }

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: message.createdAt, relativeTo: Date())
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SentMessagesView()
    }
}
