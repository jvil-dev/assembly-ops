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
    @StateObject private var areaViewModel = AreaManagementViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme

    @State private var selectedSlot: CoverageSlot?
    @State private var hasAppeared = false
    @State private var showCreatePost = false
    @State private var showCreateArea = false
    @State private var selectedAreaForDetail: AreaItem?
    @State private var preselectedCategory: AttendantMainCategory? = nil
    @State private var postToDelete: CoveragePost?
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    /// Identity token that changes when either data source updates,
    /// forcing the attendant List to re-create rather than incrementally diff.
    private var attendantListId: String {
        let areaIds = areaViewModel.areas.map(\.id).joined(separator: ",")
        let postIds = sessionPosts.map(\.id).joined(separator: ",")
        return "\(areaIds)-\(postIds)"
    }

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

    private var isAttendantDept: Bool {
        sessionState.selectedDepartment?.departmentType == "ATTENDANT"
    }

    /// Whether any posts are assigned to areas
    private var hasAreas: Bool {
        !areaViewModel.areas.isEmpty
    }

    /// Areas grouped by I/E/S category for the Attendant department.
    /// Returns a tuple per I/E/S category with matching areas (and their posts).
    private func areasForCategory(_ main: AttendantMainCategory) -> [(area: AreaItem, captainName: String?, posts: [CoveragePost])] {
        areaViewModel.areas
            .filter { $0.category == main.rawValue }
            .map { area in
                let postsInArea = sessionPosts.filter { $0.areaId == area.id }
                let captain = area.captains.first { $0.sessionId == session.id }
                return (area: area, captainName: captain?.volunteerName, posts: postsInArea)
            }
    }

    /// Posts grouped by category, preserving sort order.
    /// For non-Attendant departments (category-based grouping).
    private var groupedPosts: [(category: String, posts: [CoveragePost])] {
        let grouped = Dictionary(grouping: sessionPosts) { post -> String in
            return post.category ?? ""
        }

        let sortedKeys = grouped.keys.sorted { a, b in
            if isAttendantDept {
                return AttendantMainCategory.sortIndex(for: a) < AttendantMainCategory.sortIndex(for: b)
            }
            return a < b
        }

        let result: [(category: String, posts: [CoveragePost])] = sortedKeys.map { key in
            let categoryName: String
            if key.isEmpty {
                categoryName = "post.otherCategory".localized
            } else {
                categoryName = key
            }
            guard let postsForKey = grouped[key] else {
                return (category: categoryName, posts: [])
            }
            return (category: categoryName, posts: postsForKey)
        }

        return result
    }

    /// Display label for a category section header.
    private func categoryLabel(_ category: String) -> String {
        if isAttendantDept {
            return AttendantMainCategory.displayString(for: category)
        }
        return category
    }

    var body: some View {
        contentView
            .themedBackground(scheme: colorScheme)
            .navigationTitle(session.name)
            .toolbar { toolbarContent }
            .modifier(SessionSheetsModifier(
                selectedSlot: $selectedSlot,
                showCreatePost: $showCreatePost,
                showCreateArea: $showCreateArea,
                selectedAreaForDetail: $selectedAreaForDetail,
                preselectedCategory: $preselectedCategory,
                viewModel: viewModel,
                areaViewModel: areaViewModel,
                sessionState: sessionState,
                session: session
            ))
            .modifier(SessionLifecycleModifier(
                showCreatePost: $showCreatePost,
                showCreateArea: $showCreateArea,
                selectedAreaForDetail: $selectedAreaForDetail,
                selectedSlot: $selectedSlot,
                showDeleteConfirmation: $showDeleteConfirmation,
                postToDelete: $postToDelete,
                hasAppeared: $hasAppeared,
                preselectedCategory: $preselectedCategory,
                viewModel: viewModel,
                areaViewModel: areaViewModel,
                sessionState: sessionState,
                isAttendantDept: isAttendantDept,
                deletePost: deletePost
            ))
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.slots.isEmpty {
            LoadingView(message: "Loading posts...")
        } else if isAttendantDept {
            attendantPostList
        } else if sessionPosts.isEmpty {
            emptyState
        } else {
            postList
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            toolbarMenu
        }
    }

    private var toolbarMenu: some View {
        Menu {
            if sessionState.selectedDepartment != nil && !isAttendantDept {
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
                        Text(categoryLabel(group.category))
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

    // MARK: - Attendant Post List (I/E/S → Areas → Posts)

    /// Flattened row model for stable List diffing within each I/E/S section.
    private enum AttendantSectionRow: Identifiable {
        case areaHeader(area: AreaItem, captainName: String?, isFirst: Bool)
        case areaEmpty(area: AreaItem, animationIndex: Int)
        case post(post: CoveragePost, animationIndex: Int)
        case createArea(category: AttendantMainCategory, animationIndex: Int)

        var id: String {
            switch self {
            case .areaHeader(let area, _, _): return "header-\(area.id)"
            case .areaEmpty(let area, _): return "empty-\(area.id)"
            case .post(let post, _): return "post-\(post.id)"
            case .createArea(let category, _): return "create-\(category.rawValue)"
            }
        }
    }

    /// Build a flat array of identifiable rows for a given I/E/S category.
    private func attendantRows(for main: AttendantMainCategory, catIndex: Int) -> [AttendantSectionRow] {
        let categoryAreas = areasForCategory(main)
        var rows: [AttendantSectionRow] = []

        for (areaIndex, group) in categoryAreas.enumerated() {
            rows.append(.areaHeader(area: group.area, captainName: group.captainName, isFirst: areaIndex == 0))

            if group.posts.isEmpty {
                rows.append(.areaEmpty(area: group.area, animationIndex: catIndex * 20 + areaIndex * 5))
            } else {
                for (postIndex, post) in group.posts.enumerated() {
                    let animationIndex = catIndex * 20 + areaIndex * 5 + postIndex + 1
                    rows.append(.post(post: post, animationIndex: animationIndex))
                }
            }
        }

        rows.append(.createArea(category: main, animationIndex: catIndex * 20 + categoryAreas.count * 5))
        return rows
    }

    private var attendantPostList: some View {
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

            // I/E/S category sections → flattened rows
            ForEach(Array(AttendantMainCategory.allCases.enumerated()), id: \.element.id) { catIndex, main in
                Section {
                    ForEach(attendantRows(for: main, catIndex: catIndex)) { row in
                        attendantSectionRow(row)
                    }
                } header: {
                    Text(AttendantMainCategory.displayString(for: main.rawValue))
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
        }
        .id(attendantListId)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private func attendantSectionRow(_ row: AttendantSectionRow) -> some View {
        switch row {
        case .areaHeader(let area, let captainName, let isFirst):
            areaHeader(area: area, captainName: captainName)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(
                    top: isFirst ? 0 : AppTheme.Spacing.s,
                    leading: AppTheme.Spacing.screenEdge,
                    bottom: AppTheme.Spacing.xs,
                    trailing: AppTheme.Spacing.screenEdge
                ))
        case .areaEmpty(let area, let animationIndex):
            areaEmptyPlaceholder(area: area, animationIndex: animationIndex)
        case .post(let post, let animationIndex):
            postRow(post: post, animationIndex: animationIndex)
        case .createArea(let category, let animationIndex):
            createAreaPlaceholder(for: category, animationIndex: animationIndex)
        }
    }

    // MARK: - Area Section Header

    private func areaHeader(area: AreaItem, captainName: String?) -> some View {
        Button {
            selectedAreaForDetail = area
            HapticManager.shared.lightTap()
        } label: {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "rectangle.3.group")
                    .font(.system(size: 12))
                    .foregroundStyle(DepartmentColor.color(for: "ATTENDANT"))

                Text(area.name)
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(.primary)

                if let captainName = captainName {
                    Text("★ \(captainName)")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.themeColor)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
        }
        .buttonStyle(.plain)
        .textCase(nil)
        .listRowInsets(EdgeInsets(
            top: AppTheme.Spacing.m,
            leading: AppTheme.Spacing.screenEdge,
            bottom: AppTheme.Spacing.xs,
            trailing: AppTheme.Spacing.screenEdge
        ))
    }

    private func areaEmptyPlaceholder(area: AreaItem, animationIndex: Int) -> some View {
        Button {
            selectedAreaForDetail = area
            HapticManager.shared.lightTap()
        } label: {
            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(DepartmentColor.color(for: "ATTENDANT").opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: "rectangle.3.group")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DepartmentColor.color(for: "ATTENDANT"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("area.noPosts".localized)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Text("area.createPost".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                Spacer()

                Image(systemName: "plus.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(DepartmentColor.color(for: "ATTENDANT"))
            }
            .cardPadding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .strokeBorder(
                        DepartmentColor.color(for: "ATTENDANT").opacity(0.3),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            )
        }
        .buttonStyle(.plain)
        .entranceAnimation(hasAppeared: hasAppeared, delay: Double(animationIndex) * 0.05)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(
            top: AppTheme.Spacing.s / 2,
            leading: AppTheme.Spacing.screenEdge,
            bottom: AppTheme.Spacing.s / 2,
            trailing: AppTheme.Spacing.screenEdge
        ))
    }

    /// "Create Area" placeholder row within each I/E/S section
    private func createAreaPlaceholder(for category: AttendantMainCategory, animationIndex: Int) -> some View {
        Button {
            preselectedCategory = category
            showCreateArea = true
            HapticManager.shared.lightTap()
        } label: {
            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(DepartmentColor.color(for: "ATTENDANT").opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DepartmentColor.color(for: "ATTENDANT"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("area.createInCategory".localized)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Text("area.createInCategoryHint".localized(with: category.rawValue))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                Spacer()

                Image(systemName: "rectangle.3.group.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(DepartmentColor.color(for: "ATTENDANT"))
            }
            .cardPadding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .strokeBorder(
                        DepartmentColor.color(for: "ATTENDANT").opacity(0.3),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            )
        }
        .buttonStyle(.plain)
        .entranceAnimation(hasAppeared: hasAppeared, delay: Double(animationIndex) * 0.05)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(
            top: AppTheme.Spacing.s / 2,
            leading: AppTheme.Spacing.screenEdge,
            bottom: AppTheme.Spacing.s / 2,
            trailing: AppTheme.Spacing.screenEdge
        ))
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

// MARK: - Sheets Modifier

private struct SessionSheetsModifier: ViewModifier {
    @Binding var selectedSlot: CoverageSlot?
    @Binding var showCreatePost: Bool
    @Binding var showCreateArea: Bool
    @Binding var selectedAreaForDetail: AreaItem?
    @Binding var preselectedCategory: AttendantMainCategory?
    let viewModel: CoverageMatrixViewModel
    let areaViewModel: AreaManagementViewModel
    let sessionState: EventSessionState
    let session: EventSessionItem

    func body(content: Content) -> some View {
        content
            .sheet(item: $selectedSlot) { slot in
                SlotDetailSheet(initialSlot: slot, viewModel: viewModel)
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostSheet(
                    categorySuggestions: viewModel.existingCategories,
                    locationSuggestions: viewModel.existingLocations,
                    preselectedCategory: preselectedCategory
                )
            }
            .sheet(isPresented: $showCreateArea) {
                if let departmentId = sessionState.selectedDepartment?.id {
                    CreateAreaSheet(
                        departmentId: departmentId,
                        viewModel: areaViewModel,
                        preselectedCategory: preselectedCategory
                    )
                }
            }
            .sheet(item: $selectedAreaForDetail) { area in
                if let departmentId = sessionState.selectedDepartment?.id {
                    AreaDetailSheet(
                        area: area,
                        session: session,
                        departmentId: departmentId,
                        areaViewModel: areaViewModel,
                        coverageViewModel: viewModel
                    )
                }
            }
    }
}

// MARK: - Lifecycle Modifier

private struct SessionLifecycleModifier: ViewModifier {
    @Binding var showCreatePost: Bool
    @Binding var showCreateArea: Bool
    @Binding var selectedAreaForDetail: AreaItem?
    @Binding var selectedSlot: CoverageSlot?
    @Binding var showDeleteConfirmation: Bool
    @Binding var postToDelete: CoveragePost?
    @Binding var hasAppeared: Bool
    @Binding var preselectedCategory: AttendantMainCategory?
    let viewModel: CoverageMatrixViewModel
    let areaViewModel: AreaManagementViewModel
    let sessionState: EventSessionState
    let isAttendantDept: Bool
    let deletePost: (CoveragePost) async -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: showCreatePost) { _, isPresented in
                if !isPresented {
                    preselectedCategory = nil
                    Task { await viewModel.loadCoverage() }
                }
            }
            .onChange(of: showCreateArea) { _, isPresented in
                if !isPresented {
                    preselectedCategory = nil
                    if let departmentId = sessionState.selectedDepartment?.id {
                        Task {
                            await areaViewModel.loadAreas(departmentId: departmentId)
                            await viewModel.loadCoverage()
                        }
                    }
                }
            }
            .onChange(of: selectedAreaForDetail) { _, area in
                if area == nil {
                    if let departmentId = sessionState.selectedDepartment?.id {
                        Task {
                            await areaViewModel.loadAreas(departmentId: departmentId)
                            await viewModel.loadCoverage()
                        }
                    }
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
                if isAttendantDept, let departmentId = sessionState.selectedDepartment?.id {
                    await areaViewModel.loadAreas(departmentId: departmentId)
                }
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
                    if isAttendantDept {
                        await areaViewModel.loadAreas(departmentId: departmentId)
                    }
                }
            }
    }
}

#Preview {
    NavigationStack {
        SessionDetailView(
            session: EventSessionItem(id: "1", name: "Morning", date: Date(), startTime: Date(), assignmentCount: 5)
        )
    }
}
