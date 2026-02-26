//
//  AdminManagementView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/1/26.
//

// MARK: - Admin Management View
//
// Displays a list of all event administrators with their roles.
// App Admins can promote Department Overseers to App Admin from this screen.
//
// Sections:
//   - Admin list: Cards showing name, email, role badge, and department
//   - Promotion: Button visible only to App Admins on Department Overseer cards
//   - Empty state: Shown when no other administrators exist
//
// Features:
//   - Pull-to-refresh admin list
//   - Confirmation alert before promotion
//   - Staggered entrance animations
//   - Role badges (App Admin = theme color, Department = secondary)
//
// Access Control:
//   - All event admins can view the list
//   - Only App Admins see the "Promote" button
//   - Department Overseers see a read-only list
//

import SwiftUI
import Apollo
import Combine

struct AdminManagementView: View {
    @StateObject private var viewModel = AdminManagementViewModel()
    @ObservedObject private var sessionState = OverseerSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var adminToPromote: EventAdminItem?

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                if viewModel.isLoading && viewModel.eventAdmins.isEmpty {
                    LoadingView(message: NSLocalizedString("common.loading", comment: ""))
                } else if let error = viewModel.error {
                    ErrorView(message: error) {
                        await loadData()
                    }
                } else if viewModel.eventAdmins.isEmpty {
                    emptyState
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                } else {
                    adminsList
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle(NSLocalizedString("admin.manage.title", comment: ""))
        .refreshable { await loadData() }
        .task { await loadData() }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Admins List

    private var adminsList: some View {
        ForEach(Array(viewModel.eventAdmins.enumerated()), id: \.element.id) { index, admin in
            adminCard(admin)
                .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.05)
        }
    }

    // MARK: - Admin Card

    private func adminCard(_ admin: EventAdminItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(admin.fullName)
                        .font(AppTheme.Typography.headline)
                    Text(admin.email)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                Text(NSLocalizedString("role.department_overseer", comment: ""))
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
            }

            if let dept = admin.departmentName {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "building.2")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text(dept)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
            }

            if false { // Promote feature removed — no APP_ADMIN role
                Divider()

                Button {
                    HapticManager.shared.lightTap()
                    adminToPromote = admin
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.circle")
                        Text(NSLocalizedString("admin.promote.button", comment: ""))
                    }
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.themeColor)
                }
                .disabled(viewModel.isPromoting)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Image(systemName: "person.2")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Text(NSLocalizedString("admin.list.empty", comment: ""))
                .font(AppTheme.Typography.headline)
            Text(NSLocalizedString("admin.list.empty.subtitle", comment: ""))
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    // MARK: - Actions

    private func loadData() async {
        guard let eventId = sessionState.selectedEvent?.id else { return }
        await viewModel.loadEventAdmins(eventId: eventId)
    }

}

#Preview {
    NavigationStack {
        AdminManagementView()
    }
}
