//
//  VolunteerEventDiscoveryView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/24/26.
//

// MARK: - Volunteer Event Discovery View
//
// Shown to volunteers with no active EventVolunteer membership.
// Three paths to join an event:
//   1. Enter a department access code (auto-join, no approval)
//   2. Share your user ID with an overseer (they add you directly)
//   3. Browse public events and request to join (fallback)
//
// Data: discoverEvents query via VolunteerEventDiscoveryViewModel
//

import SwiftUI

struct VolunteerEventDiscoveryView: View {
    @StateObject private var viewModel = VolunteerEventDiscoveryViewModel()
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var hasAppeared = false
    @State private var showError = false
    @State private var accessCodeInput = ""
    @State private var copiedUserId = false
    @State private var showJoinSuccess = false

    var body: some View {
        contentWithBackground
            .onAppear(perform: handleAppearance)
            .onChange(of: viewModel.errorMessage) { _, newValue in handleErrorChange(nil, newValue) }
            .onChange(of: viewModel.accessCodeResult == nil) { _, isNil in showJoinSuccess = !isNil }
            .alert("Error", isPresented: $showError, actions: errorAlertActions, message: errorAlertMessage)
            .alert("volunteerDiscovery.joinSuccess.title".localized, isPresented: $showJoinSuccess, actions: successAlertActions, message: successAlertMessage)
            .overlay(content: loadingOverlayContent)
    }
    
    // MARK: - Body Helpers
    
    private var contentWithBackground: some View {
        mainContent
            .themedBackground(scheme: colorScheme)
    }
    
    private func handleAppearance() {
        withAnimation(AppTheme.entranceAnimation) { hasAppeared = true }
        viewModel.loadEvents()
    }
    
    private func handleErrorChange(_ oldValue: String?, _ newValue: String?) {
        showError = newValue != nil
    }
    
    @ViewBuilder
    private func errorAlertActions() -> some View {
        Button("OK") { viewModel.errorMessage = nil }
    }
    
    @ViewBuilder
    private func errorAlertMessage() -> some View {
        Text(viewModel.errorMessage ?? "")
    }
    
    @ViewBuilder
    private func successAlertActions() -> some View {
        Button("OK") {
            viewModel.accessCodeResult = nil
            dismiss()
        }
    }
    
    @ViewBuilder
    private func successAlertMessage() -> some View {
        Text("volunteerDiscovery.joinSuccess.message".localized)
    }
    
    @ViewBuilder
    private func loadingOverlayContent() -> some View {
        loadingOverlay
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                contentCards
                    .screenPadding()
                    .padding(.top, AppTheme.Spacing.xl)
                    .padding(.bottom, AppTheme.Spacing.xxl)
            }
        }
    }
    
    private var contentCards: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Primary path: access code
            accessCodeCard
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

            // Secondary path: share user ID
            userIdCard
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

            // Divider
            orBrowseDivider
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)

            if !viewModel.sentRequestIds.isEmpty {
                pendingRequestsBanner
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.18)
            }

            eventsListContent
        }
    }
    
    @ViewBuilder
    private var eventsListContent: some View {
        if viewModel.isLoading {
            loadingSkeleton
        } else if viewModel.events.isEmpty {
            emptyState
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.2)
        } else {
            // Circuit Assemblies Section
            if !viewModel.circuitAssemblies.isEmpty {
                circuitAssembliesSection
            }

            // Conventions Section
            if !viewModel.conventions.isEmpty {
                conventionsSection
            }
        }
    }

    // MARK: - Circuit Assemblies Section

    private var circuitAssembliesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            sectionHeader(icon: "person.3.fill", title: "browseEvents.section.circuitAssemblies".localized)
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.2)

            ForEach(Array(viewModel.circuitAssemblies.enumerated()), id: \.element.id) { index, event in
                eventCard(for: event)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.06 + 0.25)
            }
        }
    }

    // MARK: - Conventions Section

    private var conventionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            sectionHeader(icon: "building.columns.fill", title: "browseEvents.section.conventions".localized)
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.35)

            conventionSearchBar
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.4)

            if viewModel.filteredConventions.isEmpty && !viewModel.conventionSearchText.isEmpty {
                noSearchResultsView
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.45)
            } else {
                ForEach(Array(viewModel.filteredConventions.enumerated()), id: \.element.id) { index, event in
                    eventCard(for: event)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.06 + 0.45)
                }
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.themeColor)
            Text(title)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)
        }
        .padding(.top, AppTheme.Spacing.m)
    }

    // MARK: - Convention Search Bar

    private var conventionSearchBar: some View {
        HStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            TextField("browseEvents.search.placeholder".localized, text: $viewModel.conventionSearchText)
                .font(AppTheme.Typography.body)
            if !viewModel.conventionSearchText.isEmpty {
                Button {
                    viewModel.conventionSearchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
            }
        }
        .padding(AppTheme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(AppTheme.cardBackgroundSecondary(for: colorScheme))
        )
    }

    // MARK: - No Search Results

    private var noSearchResultsView: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Text("browseEvents.search.noResults".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xl)
    }
    
    @ViewBuilder
    private var loadingOverlay: some View {
        if viewModel.isJoiningByCode {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            ProgressView("volunteerDiscovery.joining".localized)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // Background canvas
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.themeColor.opacity(colorScheme == .dark ? 0.45 : 0.12),
                            AppTheme.themeColor.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 220)

            // Decorative radial accent
            Circle()
                .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.18 : 0.07))
                .frame(width: 260, height: 260)
                .offset(x: 100, y: -30)
                .blur(radius: 60)

            VStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.25 : 0.12))
                        .frame(width: 72, height: 72)

                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(AppTheme.themeColor)
                }

                VStack(spacing: 6) {
                    Text("volunteerDiscovery.hero.title".localized)
                        .font(.system(size: 26, weight: .bold, design: .default))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.1))

                    Text("volunteerDiscovery.hero.subtitle".localized)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.bottom, AppTheme.Spacing.xxl)
            .padding(.horizontal, AppTheme.Spacing.screenEdge)
        }
    }

    // MARK: - Access Code Card

    private var accessCodeCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("volunteerDiscovery.accessCode.header".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text("volunteerDiscovery.accessCode.title".localized)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("volunteerDiscovery.accessCode.description".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            HStack(spacing: AppTheme.Spacing.m) {
                TextField("volunteerDiscovery.accessCode.placeholder".localized, text: $accessCodeInput)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.vertical, AppTheme.Spacing.m)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .strokeBorder(AppTheme.themeColor.opacity(0.3), lineWidth: 1)
                    )

                Button {
                    HapticManager.shared.lightTap()
                    viewModel.joinByAccessCode(code: accessCodeInput)
                } label: {
                    Text("volunteerDiscovery.accessCode.join".localized)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppTheme.Spacing.l)
                        .frame(height: AppTheme.ButtonHeight.medium)
                }
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                        .fill(accessCodeInput.isEmpty ? AppTheme.themeColor.opacity(0.4) : AppTheme.themeColor)
                )
                .disabled(accessCodeInput.isEmpty || viewModel.isJoiningByCode)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - User ID Card

    private var userIdCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "person.text.rectangle")
                    .foregroundStyle(AppTheme.themeColor)
                Text("volunteerDiscovery.userId.header".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text("volunteerDiscovery.userId.title".localized)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("volunteerDiscovery.userId.description".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            if let userId = appState.currentUser?.userId {
                HStack(spacing: AppTheme.Spacing.m) {
                    Text(userId)
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Button {
                        UIPasteboard.general.string = userId
                        HapticManager.shared.lightTap()
                        withAnimation(AppTheme.quickAnimation) { copiedUserId = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(AppTheme.quickAnimation) { copiedUserId = false }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: copiedUserId ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 13))
                            Text(copiedUserId ? "volunteerDiscovery.userId.copied".localized : "volunteerDiscovery.userId.copy".localized)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(copiedUserId ? AppTheme.StatusColors.accepted : AppTheme.themeColor)
                        .padding(.horizontal, AppTheme.Spacing.m)
                        .padding(.vertical, AppTheme.Spacing.s)
                        .background(
                            Capsule()
                                .fill(copiedUserId
                                      ? AppTheme.StatusColors.acceptedBackground
                                      : AppTheme.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        )
                    }
                    .animation(AppTheme.quickAnimation, value: copiedUserId)
                }
                .padding(AppTheme.Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(AppTheme.cardBackgroundSecondary(for: colorScheme))
                )
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Or Browse Divider

    private var orBrowseDivider: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            Rectangle()
                .fill(AppTheme.textTertiary(for: colorScheme).opacity(0.3))
                .frame(height: 1)
            Text("volunteerDiscovery.orBrowse".localized)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Rectangle()
                .fill(AppTheme.textTertiary(for: colorScheme).opacity(0.3))
                .frame(height: 1)
        }
    }

    // MARK: - Pending Requests Banner

    private var pendingRequestsBanner: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(AppTheme.themeColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.themeColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString("volunteer.eventDiscovery.pendingStatus.title", comment: ""))
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.1))

                Text(NSLocalizedString("volunteer.eventDiscovery.pendingStatus.subtitle", comment: ""))
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            Spacer()

            // Pulse dot
            Circle()
                .fill(AppTheme.themeColor)
                .frame(width: 8, height: 8)
        }
        .cardPadding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.15 : 0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .strokeBorder(AppTheme.themeColor.opacity(0.3), lineWidth: 1)
        )
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
                skeletonBar(width: 110, height: 12)
                Spacer()
            }
            skeletonBar(width: 200, height: 18)
            skeletonBar(width: 160, height: 14)
            skeletonBar(width: 130, height: 14)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .redacted(reason: .placeholder)
        .shimmering()
    }

    private func skeletonBar(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(AppTheme.textTertiary(for: colorScheme).opacity(0.3))
            .frame(width: width, height: height)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(AppTheme.textTertiary(for: colorScheme).opacity(0.08))
                    .frame(width: 96, height: 96)
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            VStack(spacing: AppTheme.Spacing.s) {
                Text("volunteerDiscovery.empty.title".localized)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                Text("volunteerDiscovery.empty.subtitle".localized)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }

            Button {
                viewModel.loadEvents()
            } label: {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                    Text("Refresh")
                        .font(AppTheme.Typography.bodyMedium)
                }
                .frame(height: AppTheme.ButtonHeight.medium)
                .padding(.horizontal, AppTheme.Spacing.xxl)
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .stroke(AppTheme.themeColor, lineWidth: 1.5)
            )
            .foregroundStyle(AppTheme.themeColor)
        }
        .padding(.top, AppTheme.Spacing.xxl)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Event Card

    @ViewBuilder
    private func eventCard(for event: DiscoverableEvent) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top strip — event type label + invite badge
            HStack {
                EventTypePill(type: event.displayEventType, themeColor: AppTheme.themeColor, colorScheme: colorScheme)
                Spacer()
                if event.isInviteOnly {
                    inviteOnlyBadge
                }
            }
            .padding(.horizontal, AppTheme.Spacing.cardPadding)
            .padding(.top, AppTheme.Spacing.cardPadding)
            .padding(.bottom, AppTheme.Spacing.m)

            // Divider under header strip
            Rectangle()
                .fill(AppTheme.dividerColor(for: colorScheme))
                .frame(height: 1)
                .padding(.horizontal, AppTheme.Spacing.cardPadding)

            // Body
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                Text(event.name)
                    .font(.system(size: 20, weight: .semibold, design: .default))
                    .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.1))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                    metaRow(icon: "mappin.circle.fill", text: event.venue)
                    metaRow(icon: "calendar", text: Self.formatDateRange(event.startDate, event.endDate))
                    metaRow(icon: "person.2.fill", text: "\(event.volunteerCount) volunteers serving")
                }
            }
            .padding(.horizontal, AppTheme.Spacing.cardPadding)
            .padding(.top, AppTheme.Spacing.m)
            .padding(.bottom, event.isInviteOnly ? AppTheme.Spacing.cardPadding : AppTheme.Spacing.m)

            // Action footer
            if !event.isInviteOnly {
                Rectangle()
                    .fill(AppTheme.dividerColor(for: colorScheme))
                    .frame(height: 1)
                    .padding(.horizontal, AppTheme.Spacing.cardPadding)

                joinButtonRow(for: event)
                    .padding(.horizontal, AppTheme.Spacing.cardPadding)
                    .padding(.vertical, AppTheme.Spacing.m)
            }
        }
        .themedCard(scheme: colorScheme)
    }

    private func metaRow(icon: String, text: String) -> some View {
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

    // MARK: - Invite Only Badge

    private var inviteOnlyBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: 9))
            Text(NSLocalizedString("volunteer.eventDiscovery.inviteOnly", comment: ""))
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(AppTheme.textTertiary(for: colorScheme).opacity(0.12))
        )
        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
    }

    // MARK: - Join Button Row

    @ViewBuilder
    private func joinButtonRow(for event: DiscoverableEvent) -> some View {
        let hasSent = viewModel.sentRequestIds.contains(event.id)
        let isExpanded = viewModel.expandedEventId == event.id

        if hasSent {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.StatusColors.accepted)
                Text(NSLocalizedString("volunteer.eventDiscovery.requestSent", comment: ""))
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundStyle(AppTheme.StatusColors.accepted)
                Spacer()
            }
            .padding(.vertical, AppTheme.Spacing.xs)
        } else if isExpanded {
            departmentSelectionSection(for: event)
        } else {
            Button {
                withAnimation(AppTheme.quickAnimation) {
                    viewModel.toggleExpand(eventId: event.id)
                }
            } label: {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14))
                    Text(NSLocalizedString("volunteer.eventDiscovery.requestToJoin", comment: ""))
                        .font(AppTheme.Typography.bodyMedium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.ButtonHeight.medium)
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .fill(AppTheme.themeColor)
            )
            .foregroundStyle(.white)
        }
    }

    // MARK: - Department Selection Section

    @ViewBuilder
    private func departmentSelectionSection(for event: DiscoverableEvent) -> some View {
        let isRequesting = viewModel.pendingRequestIds.contains(event.id)

        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            if event.departments.isEmpty {
                // No departments available yet
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text("discovery.noDepartments".localized)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
                .padding(.vertical, AppTheme.Spacing.s)
            } else {
                Text("discovery.selectDepartment".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

                // Department chips in wrapping layout
                departmentChipGrid(for: event)

                // Optional note field
                TextField("discovery.notePlaceholder".localized, text: $viewModel.joinNote, axis: .vertical)
                    .font(AppTheme.Typography.body)
                    .lineLimit(1...3)
                    .padding(AppTheme.Spacing.m)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    )

                // Submit button
                Button {
                    let note = viewModel.joinNote.trimmingCharacters(in: .whitespacesAndNewlines)
                    viewModel.requestToJoin(
                        eventId: event.id,
                        departmentType: viewModel.selectedDepartmentType,
                        note: note.isEmpty ? nil : note
                    )
                } label: {
                    HStack(spacing: AppTheme.Spacing.s) {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 14))
                            Text("discovery.submitRequest".localized)
                                .font(AppTheme.Typography.bodyMedium)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.ButtonHeight.medium)
                }
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                        .fill(viewModel.selectedDepartmentType == nil || isRequesting
                              ? AppTheme.themeColor.opacity(0.4)
                              : AppTheme.themeColor)
                )
                .foregroundStyle(.white)
                .disabled(viewModel.selectedDepartmentType == nil || isRequesting)
                .animation(AppTheme.quickAnimation, value: isRequesting)
            }

            // Collapse button
            Button {
                withAnimation(AppTheme.quickAnimation) {
                    viewModel.toggleExpand(eventId: event.id)
                }
            } label: {
                Text("discovery.cancel".localized)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.xs)
            }
        }
    }

    // MARK: - Department Chip Grid

    private func departmentChipGrid(for event: DiscoverableEvent) -> some View {
        FlowLayout(spacing: AppTheme.Spacing.s) {
            ForEach(event.departments) { dept in
                departmentChip(dept: dept)
            }
        }
    }

    private func departmentChip(dept: EventDepartmentInfo) -> some View {
        let isSelected = viewModel.selectedDepartmentType == dept.departmentType
        let deptColor = DepartmentColor.color(for: dept.departmentType)

        return Button {
            withAnimation(AppTheme.quickAnimation) {
                viewModel.selectedDepartmentType = dept.departmentType
            }
            HapticManager.shared.lightTap()
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(deptColor)
                    .frame(width: 10, height: 10)

                Text(dept.name)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .padding(.horizontal, AppTheme.Spacing.m)
            .padding(.vertical, AppTheme.Spacing.s)
            .background(
                Capsule()
                    .fill(isSelected
                          ? deptColor.opacity(colorScheme == .dark ? 0.3 : 0.15)
                          : AppTheme.cardBackgroundSecondary(for: colorScheme))
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? deptColor : Color.clear, lineWidth: 1.5)
            )
            .foregroundStyle(isSelected
                             ? deptColor
                             : AppTheme.textSecondary(for: colorScheme))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private static func formatDateRange(_ start: String, _ end: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, yyyy"
        let startStr = DateUtils.parseISO8601(start).map { fmt.string(from: $0) } ?? start
        let endStr = DateUtils.parseISO8601(end).map { fmt.string(from: $0) } ?? end
        return "\(startStr) – \(endStr)"
    }
}

// MARK: - Event Type Pill

private struct EventTypePill: View {
    let type: String
    let themeColor: Color
    let colorScheme: ColorScheme

    var body: some View {
        Text(type.uppercased())
            .font(.system(size: 10, weight: .bold, design: .default))
            .tracking(0.8)
            .padding(.horizontal, AppTheme.Spacing.m)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(themeColor.opacity(colorScheme == .dark ? 0.25 : 0.1))
            )
            .foregroundStyle(themeColor)
    }
}

// MARK: - Shimmer Modifier (skeleton loading)

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.35), location: 0.4),
                            .init(color: .clear, location: 0.8)
                        ],
                        startPoint: .init(x: phase, y: 0.5),
                        endPoint: .init(x: phase + 0.6, y: 0.5)
                    )
                    .blendMode(.plusLighter)
                }
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.4)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1.4
                }
            }
    }
}

private extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

#Preview {
    VolunteerEventDiscoveryView()
}
