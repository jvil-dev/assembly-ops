//
//  SessionDetailView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/19/26.
//

// MARK: - Session Detail View
//
// Drill-down from session list showing posts for a specific session.
// Each post card displays assignment coverage and volunteer names.
// Tap a post to open SlotDetailSheet for assignment management.
//
// Features:
//   - Warm gradient background with entrance animations
//   - Post cards with coverage status (filled/capacity)
//   - Volunteer names listed on each card
//   - Filter menu: show all, gaps only, or filled only
//   - Tap post card → SlotDetailSheet for managing assignments
//   - Pull-to-refresh
//
// Navigation:
//   Parent: AssignmentsView (session list)
//   Child: SlotDetailSheet (assign volunteers)

import SwiftUI
import Apollo

struct SessionDetailView: View {
    let session: EventSessionItem

    @StateObject private var viewModel = CoverageMatrixViewModel()
    @ObservedObject private var sessionState = OverseerSessionState.shared
    @Environment(\.colorScheme) var colorScheme

    @State private var selectedSlot: CoverageSlot?
    @State private var hasAppeared = false
    @State private var showCreatePost = false
    @State private var postToDelete: CoveragePost?
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    private var sessionSlots: [CoverageSlot] {
        viewModel.slots(for: session.id)
    }

    /// Unique posts that have slots in this session
    private var sessionPosts: [CoveragePost] {
        let postIds = Set(sessionSlots.map { $0.postId })
        return viewModel.posts.filter { postIds.contains($0.id) }
    }

    /// Whether any posts have categories assigned
    private var hasCategories: Bool {
        sessionPosts.contains { $0.category != nil }
    }

    /// Posts grouped by category, preserving sort order
    private var groupedPosts: [(category: String, posts: [CoveragePost])] {
        let grouped = Dictionary(grouping: sessionPosts) { $0.category ?? "" }
        return grouped.keys.sorted().map { key in
            (category: key.isEmpty ? "post.otherCategory".localized : key, posts: grouped[key]!)
        }
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.slots.isEmpty {
                LoadingView(message: "Loading posts...")
            } else if sessionPosts.isEmpty {
                emptyState
            } else {
                postList
            }
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle(session.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if sessionState.selectedDepartment != nil {
                        Button {
                            showCreatePost = true
                        } label: {
                            Label("post.create".localized, systemImage: "mappin.circle.fill")
                        }

                        Divider()
                    }

                    Button {
                        viewModel.filter = .all
                    } label: {
                        Label("Show All", systemImage: viewModel.filter == .all ? "checkmark" : "")
                    }

                    Button {
                        viewModel.filter = .gaps
                    } label: {
                        Label("Gaps Only", systemImage: viewModel.filter == .gaps ? "checkmark" : "")
                    }

                    Button {
                        viewModel.filter = .filled
                    } label: {
                        Label("Filled Only", systemImage: viewModel.filter == .filled ? "checkmark" : "")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(item: $selectedSlot) { slot in
            SlotDetailSheet(initialSlot: slot, viewModel: viewModel)
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostSheet(
                categorySuggestions: viewModel.existingCategories,
                locationSuggestions: viewModel.existingLocations
            )
        }
        .onChange(of: showCreatePost) { _, isPresented in
            if !isPresented {
                Task { await viewModel.loadCoverage() }
            }
        }
        .onChange(of: selectedSlot) { _, slot in
            if slot == nil {
                Task { await viewModel.loadCoverage() }
            }
        }
        .alert("Delete Post", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                postToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let post = postToDelete {
                    Task { await deletePost(post) }
                }
            }
        } message: {
            if let post = postToDelete {
                Text("Are you sure you want to delete \"\(post.name)\"? This will also remove all assignments for this post.")
            }
        }
        .refreshable {
            await viewModel.loadCoverage()
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
        .task {
            if let departmentId = sessionState.selectedDepartment?.id {
                viewModel.departmentId = departmentId
                await viewModel.loadCoverage()
            }
        }
    }

    // MARK: - Post List

    private var postList: some View {
        List {
            // Session summary
            summaryCard
                .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(
                    top: AppTheme.Spacing.l,
                    leading: AppTheme.Spacing.screenEdge,
                    bottom: AppTheme.Spacing.s,
                    trailing: AppTheme.Spacing.screenEdge
                ))

            if hasCategories {
                ForEach(Array(groupedPosts.enumerated()), id: \.element.category) { groupIndex, group in
                    Section {
                        ForEach(Array(group.posts.enumerated()), id: \.element.id) { postIndex, post in
                            let animationIndex = groupIndex * 10 + postIndex
                            postRow(post: post, animationIndex: animationIndex)
                        }
                    } header: {
                        Text(group.category)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            .textCase(nil)
                            .listRowInsets(EdgeInsets(
                                top: AppTheme.Spacing.m,
                                leading: AppTheme.Spacing.screenEdge,
                                bottom: AppTheme.Spacing.xs,
                                trailing: AppTheme.Spacing.screenEdge
                            ))
                    }
                }
            } else {
                ForEach(Array(sessionPosts.enumerated()), id: \.element.id) { index, post in
                    postRow(post: post, animationIndex: index)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func postRow(post: CoveragePost, animationIndex: Int) -> some View {
        Group {
            if let slot = viewModel.slot(for: post.id, session: session.id) {
                Button {
                    selectedSlot = slot
                } label: {
                    postCard(slot: slot, post: post)
                }
                .buttonStyle(.plain)
                .entranceAnimation(hasAppeared: hasAppeared, delay: Double(animationIndex) * 0.03 + 0.05)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                postToDelete = post
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(
            top: AppTheme.Spacing.s / 2,
            leading: AppTheme.Spacing.screenEdge,
            bottom: AppTheme.Spacing.s / 2,
            trailing: AppTheme.Spacing.screenEdge
        ))
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        let totalSlots = sessionSlots.count
        let filledSlots = sessionSlots.filter { $0.isFilled }.count
        let totalAssigned = sessionSlots.reduce(0) { $0 + $1.filled }
        let totalCapacity = sessionSlots.reduce(0) { $0 + $1.capacity }

        return HStack(spacing: AppTheme.Spacing.xl) {
            statBadge(value: "\(sessionPosts.count)", label: "Posts")
            statBadge(value: "\(filledSlots)/\(totalSlots)", label: "Filled")
            statBadge(value: "\(totalAssigned)/\(totalCapacity)", label: "Volunteers")
        }
        .frame(maxWidth: .infinity)
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .screenPadding()
        .padding(.top, AppTheme.Spacing.l)
        .padding(.bottom, AppTheme.Spacing.s)
    }

    private func statBadge(value: String, label: String) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(value)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.themeColor)
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
    }

    // MARK: - Post Card

    private func postCard(slot: CoverageSlot, post: CoveragePost) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Post header
            HStack {
                Text(post.name)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)

                Spacer()

                // Coverage badge
                Text("\(slot.filled)/\(slot.capacity)")
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(statusColor(for: slot))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusBackground(for: slot))
                    .clipShape(Capsule())
            }

            // Assigned volunteers
            if slot.assignments.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 12))
                    Text("No volunteers assigned")
                }
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(slot.assignments) { assignment in
                        HStack(spacing: AppTheme.Spacing.s) {
                            // Initials circle
                            ZStack {
                                Circle()
                                    .fill(volunteerColor(assignment).opacity(0.15))
                                    .frame(width: 28, height: 28)

                                Text(initials(for: assignment.volunteer))
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(volunteerColor(assignment))
                            }

                            Text("\(assignment.volunteer.firstName) \(assignment.volunteer.lastName)")
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(.primary)

                            Spacer()

                            if assignment.checkIn != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppTheme.StatusColors.accepted)
                            } else if assignment.isPending {
                                Image(systemName: "clock")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppTheme.StatusColors.pending)
                            }
                        }
                    }
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Spacer()

            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Text("No Posts")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("Create posts for your department to start assigning volunteers to this session.")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            if sessionState.selectedDepartment != nil {
                Button {
                    showCreatePost = true
                } label: {
                    Label("post.create".localized, systemImage: "plus.circle")
                        .font(AppTheme.Typography.bodyMedium)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.themeColor)
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.screenEdge)
        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
    }

    // MARK: - Actions

    private func deletePost(_ post: CoveragePost) async {
        isDeleting = true
        do {
            let _ = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.DeletePostMutation(id: post.id)
            )
            HapticManager.shared.success()
            await viewModel.loadCoverage()
        } catch {
            HapticManager.shared.error()
        }
        postToDelete = nil
        isDeleting = false
    }

    // MARK: - Helpers

    private func statusColor(for slot: CoverageSlot) -> Color {
        if slot.isFilled {
            return AppTheme.StatusColors.accepted
        } else if slot.filled > 0 {
            return AppTheme.StatusColors.warning
        } else if slot.pendingCount > 0 {
            return AppTheme.StatusColors.pending
        } else {
            return AppTheme.StatusColors.declined
        }
    }

    private func statusBackground(for slot: CoverageSlot) -> Color {
        if slot.isFilled {
            return AppTheme.StatusColors.acceptedBackground
        } else if slot.filled > 0 {
            return AppTheme.StatusColors.warningBackground
        } else if slot.pendingCount > 0 {
            return AppTheme.StatusColors.pendingBackground
        } else {
            return AppTheme.StatusColors.declinedBackground
        }
    }

    private func initials(for volunteer: CoverageVolunteer) -> String {
        let first = volunteer.firstName.prefix(1)
        let last = volunteer.lastName.prefix(1)
        return String(first + last).uppercased()
    }

    private func volunteerColor(_ assignment: CoverageAssignment) -> Color {
        if assignment.checkIn != nil { return AppTheme.StatusColors.accepted }
        if assignment.isPending { return AppTheme.StatusColors.pending }
        return AppTheme.themeColor
    }
}

#Preview {
    NavigationStack {
        SessionDetailView(
            session: EventSessionItem(id: "1", name: "Morning", date: Date(), startTime: Date(), assignmentCount: 5)
        )
    }
}
