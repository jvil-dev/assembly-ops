//
//  AreaDetailSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

// MARK: - Area Detail Sheet
//
// Drill-down into an area showing its posts and captain assignment for the current session.
// Overseer can:
//   - View/edit area name and description
//   - See all posts in the area
//   - Create new posts directly inside the area
//   - Assign/remove captain for the current session
//   - Delete the area
//

import SwiftUI

struct AreaDetailSheet: View {
    let area: AreaItem
    let session: EventSessionItem
    let departmentId: String
    @ObservedObject var areaViewModel: AreaManagementViewModel
    @ObservedObject var coverageViewModel: CoverageMatrixViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var isEditing = false
    @State private var editName = ""
    @State private var editDescription = ""
    @State private var showDeleteConfirmation = false
    @State private var showCaptainPicker = false
    @State private var showCreatePost = false
    @State private var showError = false
    @State private var isDeleting = false
    @State private var postToDelete: CoveragePost?
    @State private var showDeletePostConfirmation = false

    private var currentCaptain: AreaCaptainItem? {
        area.captains.first { $0.sessionId == session.id }
    }

    /// Posts in this area from the coverage data
    private var areaPosts: [CoveragePost] {
        coverageViewModel.posts.filter { $0.areaId == area.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    areaInfoCard
                    captainCard
                    postsCard
                    deleteButton
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle(area.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.done".localized) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(isEditing ? "common.save".localized : "common.edit".localized) {
                        if isEditing {
                            Task { await saveEdits() }
                        } else {
                            editName = area.name
                            editDescription = area.description ?? ""
                            isEditing = true
                        }
                    }
                }
            }
            .alert("area.deleteConfirm".localized, isPresented: $showDeleteConfirmation) {
                Button("common.cancel".localized, role: .cancel) {}
                Button("common.delete".localized, role: .destructive) {
                    Task { await deleteArea() }
                }
            } message: {
                Text("area.deleteWarning".localized)
            }
            .alert("area.deletePostConfirm".localized, isPresented: $showDeletePostConfirmation) {
                Button("common.cancel".localized, role: .cancel) {
                    postToDelete = nil
                }
                Button("common.delete".localized, role: .destructive) {
                    if let post = postToDelete {
                        Task { await deletePost(post) }
                    }
                }
            } message: {
                if let post = postToDelete {
                    Text(String(format: "area.deletePostWarning".localized, post.name))
                }
            }
            .alert("common.error".localized, isPresented: $showError) {
                Button("common.ok".localized) { areaViewModel.error = nil }
            } message: {
                if let error = areaViewModel.error {
                    Text(error)
                }
            }
            .onChange(of: areaViewModel.error) { _, error in
                if error != nil { showError = true }
            }
            .sheet(isPresented: $showCaptainPicker) {
                VolunteerPickerForCaptain(
                    departmentId: departmentId,
                    onSelect: { eventVolunteerId, forceAssigned, acceptedDeadline in
                        Task {
                            await areaViewModel.setAreaCaptain(
                                areaId: area.id,
                                sessionId: session.id,
                                eventVolunteerId: eventVolunteerId,
                                forceAssigned: forceAssigned,
                                acceptedDeadline: acceptedDeadline
                            )
                            showCaptainPicker = false
                        }
                    }
                )
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostSheet(
                    categorySuggestions: coverageViewModel.existingCategories,
                    locationSuggestions: coverageViewModel.existingLocations,
                    areaId: area.id,
                    areaCategory: area.category
                )
            }
            .onChange(of: showCreatePost) { _, isPresented in
                if !isPresented {
                    Task {
                        await coverageViewModel.loadCoverage()
                        await areaViewModel.loadAreas(departmentId: departmentId)
                    }
                }
            }
        }
    }

    // MARK: - Area Info Card

    private var areaInfoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "rectangle.3.group", title: "area.details".localized)

            if isEditing {
                VStack(spacing: AppTheme.Spacing.m) {
                    themedTextField("area.name".localized, text: $editName)
                    themedTextField("area.description".localized, text: $editDescription)
                }
            } else {
                HStack(spacing: AppTheme.Spacing.s) {
                    Text(area.name)
                        .font(AppTheme.Typography.headline)

                    if let category = area.category {
                        Text(category)
                            .font(AppTheme.Typography.caption)
                            .padding(.horizontal, AppTheme.Spacing.s)
                            .padding(.vertical, 3)
                            .background(DepartmentColor.color(for: "ATTENDANT").opacity(0.15))
                            .foregroundStyle(DepartmentColor.color(for: "ATTENDANT"))
                            .clipShape(Capsule())
                    }
                }

                if let description = area.description, !description.isEmpty {
                    Text(description)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Captain Card

    private var captainCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack {
                SectionHeaderLabel(icon: "star.fill", title: "area.captain".localized)
                Spacer()
                Text(session.name)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            if let captain = currentCaptain {
                HStack {
                    ZStack {
                        Circle()
                            .fill(DepartmentColor.color(for: "ATTENDANT").opacity(0.15))
                            .frame(width: 36, height: 36)
                        Text(captainInitials(captain.volunteerName))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(DepartmentColor.color(for: "ATTENDANT"))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(captain.volunteerName)
                            .font(AppTheme.Typography.bodyMedium)

                        HStack(spacing: 6) {
                            AssignmentStatusBadgeCompact(status: captain.status)

                            if captain.forceAssigned {
                                Text("captain.assignment.forceAssigned".localized)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            }
                        }
                    }

                    Spacer()

                    Menu {
                        Button {
                            showCaptainPicker = true
                        } label: {
                            Label("area.changeCaptain".localized, systemImage: "arrow.triangle.2.circlepath")
                        }
                        Button(role: .destructive) {
                            Task {
                                await areaViewModel.removeAreaCaptain(
                                    areaId: area.id,
                                    sessionId: session.id
                                )
                            }
                        } label: {
                            Label("area.removeCaptain".localized, systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                }

                // Show decline reason if captain declined
                if captain.status == .declined || captain.status == .autoDeclined,
                   let reason = captain.declineReason, !reason.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "text.quote")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.StatusColors.declined)
                        Text(reason)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                            .italic()
                    }
                    .padding(AppTheme.Spacing.s)
                    .background(AppTheme.StatusColors.declinedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                }
            } else {
                Button {
                    showCaptainPicker = true
                    HapticManager.shared.lightTap()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(DepartmentColor.color(for: "ATTENDANT"))
                        Text("area.assignCaptain".localized)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(DepartmentColor.color(for: "ATTENDANT"))
                    }
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Posts Card

    private var postsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack {
                SectionHeaderLabel(icon: "mappin.circle", title: "area.posts".localized)

                Spacer()

                Text("\(areaPosts.count)")
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            if areaPosts.isEmpty {
                Text("area.noPosts".localized)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppTheme.Spacing.m)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(areaPosts.enumerated()), id: \.element.id) { index, post in
                        postRow(post: post, isLast: index == areaPosts.count - 1)
                    }
                }
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
            }

            // Create Post button
            Button {
                showCreatePost = true
                HapticManager.shared.lightTap()
            } label: {
                HStack {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(DepartmentColor.color(for: "ATTENDANT"))
                    Text("area.createPost".localized)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(DepartmentColor.color(for: "ATTENDANT"))
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private func postRow(post: CoveragePost, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(post.name)
                    .font(AppTheme.Typography.body)

                Spacer()

                Button {
                    postToDelete = post
                    showDeletePostConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.StatusColors.declined.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppTheme.Spacing.m)
            .padding(.vertical, AppTheme.Spacing.m)

            if !isLast {
                Divider()
                    .padding(.leading, AppTheme.Spacing.m)
            }
        }
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("area.delete".localized)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.ButtonHeight.medium)
            .font(AppTheme.Typography.bodyMedium)
            .foregroundStyle(.red)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
        }
        .disabled(isDeleting)
    }

    // MARK: - Themed Text Field

    private func themedTextField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            TextField("", text: text)
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
    }

    // MARK: - Actions

    private func saveEdits() async {
        let trimmedName = editName.trimmingCharacters(in: .whitespaces)
        let trimmedDesc = editDescription.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        await areaViewModel.updateArea(
            id: area.id,
            name: trimmedName,
            description: trimmedDesc.isEmpty ? nil : trimmedDesc,
            sortOrder: nil
        )
        isEditing = false
        if areaViewModel.error == nil {
            HapticManager.shared.success()
        }
    }

    private func deleteArea() async {
        isDeleting = true
        await areaViewModel.deleteArea(id: area.id)
        isDeleting = false
        if areaViewModel.error == nil {
            HapticManager.shared.success()
            dismiss()
        }
    }

    private func deletePost(_ post: CoveragePost) async {
        do {
            let _ = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.DeletePostMutation(id: post.id)
            )
            HapticManager.shared.success()
            await coverageViewModel.loadCoverage()
            await areaViewModel.loadAreas(departmentId: departmentId)
        } catch {
            areaViewModel.error = error.localizedDescription
            HapticManager.shared.error()
        }
        postToDelete = nil
    }

    private func captainInitials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return String(first + last).uppercased()
    }
}

#Preview {
    AreaDetailSheet(
        area: AreaItem(
            id: "area-1", name: "Main Entrance",
            description: "Front doors and lobby area",
            category: "EXTERIOR", sortOrder: 1, postCount: 3,
            posts: [], captains: []
        ),
        session: EventSessionItem(
            id: "s1", name: "Morning Session",
            date: Date(), startTime: Date(), assignmentCount: 5
        ),
        departmentId: "dept-1",
        areaViewModel: AreaManagementViewModel(),
        coverageViewModel: CoverageMatrixViewModel()
    )
}

// MARK: - Volunteer Picker for Captain

struct VolunteerPickerForCaptain: View {
    let departmentId: String
    let onSelect: (String, Bool, Date?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = VolunteersViewModel()

    @State private var searchText = ""
    @State private var selectedVolunteer: VolunteerListItem?
    @State private var forceAssigned = false
    @State private var setDeadline = false
    @State private var acceptedDeadline = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()

    private var filteredVolunteers: [VolunteerListItem] {
        if searchText.isEmpty {
            return viewModel.volunteers
        }
        let query = searchText.lowercased()
        return viewModel.volunteers.filter {
            $0.firstName.lowercased().contains(query) ||
            $0.lastName.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let volunteer = selectedVolunteer {
                    assignmentOptionsView(volunteer: volunteer)
                } else {
                    volunteerListView
                }
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle(selectedVolunteer != nil ? "area.assignOptions".localized : "area.selectCaptain".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        if selectedVolunteer != nil {
                            selectedVolunteer = nil
                            forceAssigned = false
                            setDeadline = false
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .tint(DepartmentColor.color(for: "ATTENDANT"))
            .task {
                viewModel.departmentId = departmentId
                await viewModel.loadVolunteers()
            }
        }
    }

    // MARK: - Volunteer List

    private var volunteerListView: some View {
        List {
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else if filteredVolunteers.isEmpty {
                Text("No volunteers found")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    .listRowBackground(Color.clear)
            } else {
                ForEach(filteredVolunteers) { volunteer in
                    Button {
                        selectedVolunteer = volunteer
                        HapticManager.shared.lightTap()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(volunteer.firstName) \(volunteer.lastName)")
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(.primary)
                                Text(volunteer.congregation)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(DepartmentColor.color(for: "ATTENDANT"))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .searchable(text: $searchText, prompt: "common.search".localized)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Assignment Options

    private func assignmentOptionsView(volunteer: VolunteerListItem) -> some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Selected volunteer card
                HStack(spacing: AppTheme.Spacing.m) {
                    ZStack {
                        Circle()
                            .fill(DepartmentColor.color(for: "ATTENDANT").opacity(0.15))
                            .frame(width: 44, height: 44)
                        Text(initials(volunteer.firstName, volunteer.lastName))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(DepartmentColor.color(for: "ATTENDANT"))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(volunteer.firstName) \(volunteer.lastName)")
                            .font(AppTheme.Typography.bodyMedium)
                        Text(volunteer.congregation)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }

                    Spacer()
                }
                .cardPadding()
                .themedCard(scheme: colorScheme)

                // Assignment options card
                VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                    SectionHeaderLabel(icon: "gearshape", title: "captain.assignment.options".localized)

                    // Force assign toggle
                    Toggle(isOn: $forceAssigned) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("captain.assignment.forceAssign".localized)
                                .font(AppTheme.Typography.body)
                            Text("captain.assignment.forceAssignDesc".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }
                    }
                    .tint(DepartmentColor.color(for: "ATTENDANT"))

                    if !forceAssigned {
                        Divider()

                        // Deadline toggle
                        Toggle(isOn: $setDeadline) {
                            Text("captain.assignment.setDeadline".localized)
                                .font(AppTheme.Typography.body)
                        }
                        .tint(DepartmentColor.color(for: "ATTENDANT"))

                        if setDeadline {
                            DatePicker(
                                "captain.assignment.deadline".localized,
                                selection: $acceptedDeadline,
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .font(AppTheme.Typography.body)
                        }
                    }
                }
                .cardPadding()
                .themedCard(scheme: colorScheme)

                // Assign button
                Button {
                    let deadline = (!forceAssigned && setDeadline) ? acceptedDeadline : nil
                    onSelect(volunteer.id, forceAssigned, deadline)
                    HapticManager.shared.success()
                } label: {
                    Text("captain.assignment.assign".localized)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.ButtonHeight.large)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(.white)
                        .background(DepartmentColor.color(for: "ATTENDANT"))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }

    private func initials(_ firstName: String, _ lastName: String) -> String {
        let f = firstName.prefix(1)
        let l = lastName.prefix(1)
        return String(f + l).uppercased()
    }
}
