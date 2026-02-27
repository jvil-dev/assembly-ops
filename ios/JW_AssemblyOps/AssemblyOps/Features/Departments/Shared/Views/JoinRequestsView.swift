//
//  JoinRequestsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/24/26.
//

// MARK: - Join Requests View
//
// Overseer view to review pending volunteer join requests for their event.
//
// Features:
//   - Lists PENDING requests with user name, congregation, appointment, dept preference, note
//   - "Approve" → generates credentials, shows overlay for overseer to share
//   - "Deny" → removes from list
//   - Empty state when no pending requests
//

import SwiftUI

struct JoinRequestsView: View {
    let eventId: String
    @StateObject private var viewModel = JoinRequestsViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showError = false
    @State private var showCredentials = false

    var body: some View {
        ScrollView {
            contentStack
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle(NSLocalizedString("volunteer.joinRequest.pending", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) { hasAppeared = true }
            viewModel.loadRequests(eventId: eventId)
        }
        .onChange(of: viewModel.errorMessage) { _, error in
            showError = error != nil
        }
        .onChange(of: viewModel.approvedCredentials) { _, creds in
            showCredentials = creds != nil
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showCredentials, onDismiss: {
            viewModel.approvedCredentials = nil
        }) {
            if let creds = viewModel.approvedCredentials {
                CredentialsOverlayView(credentials: creds)
            }
        }
    }

    // MARK: - Content Stack

    @ViewBuilder
    private var contentStack: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            if viewModel.isLoading {
                loadingSkeleton
            } else if viewModel.requests.isEmpty {
                emptyState
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
            } else {
                // Count header
                requestCountHeader
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                ForEach(Array(viewModel.requests.enumerated()), id: \.element.id) { index, request in
                    requestCard(for: request)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.06 + 0.04)
                }
            }
        }
        .screenPadding()
        .padding(.top, AppTheme.Spacing.l)
        .padding(.bottom, AppTheme.Spacing.xxl)
    }

    // MARK: - Count Header

    private var requestCountHeader: some View {
        HStack(spacing: AppTheme.Spacing.s) {
            ZStack {
                Circle()
                    .fill(AppTheme.StatusColors.pendingBackground)
                    .frame(width: 28, height: 28)
                Text("\(viewModel.requests.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.StatusColors.pending)
            }
            Text(viewModel.requests.count == 1 ? "pending request" : "pending requests")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            Spacer()
        }
        .padding(.bottom, -AppTheme.Spacing.s)
    }

    // MARK: - Loading Skeleton

    private var loadingSkeleton: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ForEach(0..<3, id: \.self) { _ in
                skeletonCard
            }
        }
    }

    private var skeletonCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack {
                skeletonBar(width: 150, height: 18)
                Spacer()
                skeletonBar(width: 60, height: 12)
            }
            skeletonBar(width: 100, height: 12)
            skeletonBar(width: 180, height: 12)
            HStack(spacing: AppTheme.Spacing.m) {
                skeletonBar(width: .infinity, height: 44)
                skeletonBar(width: .infinity, height: 44)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .redacted(reason: .placeholder)
    }

    private func skeletonBar(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(AppTheme.textTertiary(for: colorScheme).opacity(0.3))
            .frame(width: width == .infinity ? nil : width, height: height)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(AppTheme.StatusColors.acceptedBackground)
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(AppTheme.StatusColors.accepted)
            }

            VStack(spacing: AppTheme.Spacing.s) {
                Text("All Caught Up")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.1))

                Text("No pending join requests for this event.")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppTheme.Spacing.xxl)
    }

    // MARK: - Request Card

    @ViewBuilder
    private func requestCard(for request: JoinRequestItem) -> some View {
        let isProcessing = viewModel.processingIds.contains(request.id)

        VStack(alignment: .leading, spacing: 0) {
            // Card header — name, userId, timestamp
            HStack(alignment: .top, spacing: AppTheme.Spacing.m) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.25 : 0.12))
                        .frame(width: 44, height: 44)
                    Text(request.userInitials)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.themeColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(request.userFullName)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.1))

                    Text(request.userId)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                Spacer()

                // Time ago badge
                if let timeAgo = request.timeAgoString {
                    Text(timeAgo)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        .padding(.horizontal, AppTheme.Spacing.s)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(AppTheme.textTertiary(for: colorScheme).opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.cardPadding)
            .padding(.top, AppTheme.Spacing.cardPadding)
            .padding(.bottom, AppTheme.Spacing.m)

            Rectangle()
                .fill(AppTheme.dividerColor(for: colorScheme))
                .frame(height: 1)
                .padding(.horizontal, AppTheme.Spacing.cardPadding)

            // Detail rows
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                if let congregation = request.userCongregation {
                    detailRow(icon: "building.2", text: congregation)
                }
                if let appointment = request.displayAppointment {
                    detailRow(icon: "shield.fill", text: appointment, tinted: true)
                }
                if let dept = request.displayDepartment {
                    detailRow(icon: "tag.fill", text: "Requested: \(dept)")
                }
                if let note = request.note, !note.isEmpty {
                    detailRow(icon: "text.bubble", text: note, isNote: true)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.cardPadding)
            .padding(.top, AppTheme.Spacing.m)
            .padding(.bottom, AppTheme.Spacing.m)

            Rectangle()
                .fill(AppTheme.dividerColor(for: colorScheme))
                .frame(height: 1)
                .padding(.horizontal, AppTheme.Spacing.cardPadding)

            // Action buttons
            HStack(spacing: AppTheme.Spacing.m) {
                // Deny
                Button {
                    viewModel.deny(requestId: request.id)
                } label: {
                    Group {
                        if isProcessing {
                            ProgressView().tint(AppTheme.StatusColors.declined).scaleEffect(0.85)
                        } else {
                            HStack(spacing: AppTheme.Spacing.xs) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .semibold))
                                Text(NSLocalizedString("overseer.joinRequests.deny", comment: ""))
                                    .font(AppTheme.Typography.bodyMedium)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.ButtonHeight.medium)
                }
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                        .stroke(AppTheme.StatusColors.declined.opacity(0.6), lineWidth: 1.5)
                )
                .foregroundStyle(AppTheme.StatusColors.declined)
                .disabled(isProcessing)

                // Approve
                Button {
                    viewModel.approve(requestId: request.id)
                } label: {
                    Group {
                        if isProcessing {
                            ProgressView().tint(.white).scaleEffect(0.85)
                        } else {
                            HStack(spacing: AppTheme.Spacing.xs) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                Text(NSLocalizedString("overseer.joinRequests.approve", comment: ""))
                                    .font(AppTheme.Typography.bodyMedium)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.ButtonHeight.medium)
                }
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                        .fill(AppTheme.StatusColors.accepted)
                )
                .foregroundStyle(.white)
                .disabled(isProcessing)
            }
            .padding(.horizontal, AppTheme.Spacing.cardPadding)
            .padding(.vertical, AppTheme.Spacing.m)
        }
        .themedCard(scheme: colorScheme)
    }

    private func detailRow(icon: String, text: String, tinted: Bool = false, isNote: Bool = false) -> some View {
        HStack(alignment: isNote ? .top : .center, spacing: AppTheme.Spacing.s) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(tinted ? AppTheme.themeColor : AppTheme.themeColor.opacity(0.6))
                .frame(width: 18)
            Text(text)
                .font(isNote ? AppTheme.Typography.caption : AppTheme.Typography.subheadline)
                .foregroundStyle(isNote
                                 ? AppTheme.textSecondary(for: colorScheme)
                                 : AppTheme.textSecondary(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - JoinRequestItem Extensions

extension JoinRequestItem {
    var userInitials: String {
        let parts = userFullName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(userFullName.prefix(2)).uppercased()
    }

    var timeAgoString: String? {
        DateUtils.parseISO8601(createdAt).map { DateUtils.timeAgo(from: $0) }
    }
}

// MARK: - Credentials Overlay

struct CredentialsOverlayView: View {
    let credentials: ApprovedCredentials
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var copiedId = false
    @State private var copiedToken = false
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xxl) {
                    // Success header
                    successHeader
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Credentials card
                    credentialsCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.07)

                    // Footer note
                    Text("Store these credentials securely. The volunteer will use them to sign in at the event.")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.14)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.xl)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("Credentials")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) { hasAppeared = true }
            }
        }
    }

    // MARK: - Success Header

    private var successHeader: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            ZStack {
                Circle()
                    .fill(AppTheme.StatusColors.acceptedBackground)
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.StatusColors.accepted)
            }

            VStack(spacing: AppTheme.Spacing.s) {
                Text("\(credentials.userFullName) approved!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.1))
                    .multilineTextAlignment(.center)

                Text("Share these credentials so they can sign in with their printed card.")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Credentials Card

    private var credentialsCard: some View {
        VStack(spacing: 0) {
            credentialRow(
                label: "VOLUNTEER ID",
                value: credentials.volunteerId,
                icon: "person.text.rectangle",
                copied: copiedId
            ) {
                UIPasteboard.general.string = credentials.volunteerId
                copiedId = true
                HapticManager.shared.lightTap()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedId = false }
            }

            Rectangle()
                .fill(AppTheme.dividerColor(for: colorScheme))
                .frame(height: 1)
                .padding(.horizontal, AppTheme.Spacing.cardPadding)

            credentialRow(
                label: "TOKEN",
                value: credentials.token,
                icon: "key.fill",
                copied: copiedToken
            ) {
                UIPasteboard.general.string = credentials.token
                copiedToken = true
                HapticManager.shared.lightTap()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedToken = false }
            }
        }
        .themedCard(scheme: colorScheme)
    }

    private func credentialRow(
        label: String,
        value: String,
        icon: String,
        copied: Bool,
        onCopy: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.themeColor.opacity(0.7))
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            HStack(alignment: .center) {
                Text(value)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.1))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                Button {
                    onCopy()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12, weight: .medium))
                        Text(copied ? "Copied" : "Copy")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(copied
                                  ? AppTheme.StatusColors.acceptedBackground
                                  : AppTheme.themeColor.opacity(0.1))
                    )
                    .foregroundStyle(copied ? AppTheme.StatusColors.accepted : AppTheme.themeColor)
                    .animation(AppTheme.quickAnimation, value: copied)
                }
            }
        }
        .padding(AppTheme.Spacing.cardPadding)
    }
}

#Preview {
    NavigationStack {
        JoinRequestsView(eventId: "preview-event-id")
    }
}
