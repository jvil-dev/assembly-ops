//
//  VolunteerListView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Volunteer List View
//
// Main volunteer management screen for overseers.
// Uses the app's design system with warm background and floating cards.
//
// Tabs:
//   - My Department: Editable list of volunteers in overseer's department
//   - All Volunteers: Read-only view of entire event roster
//
// Features:
//   - Warm gradient background
//   - Floating volunteer cards with avatar and details
//   - Search by name or congregation
//   - Add new volunteers (My Department tab only)
//   - Segmented picker for tab switching
//   - Staggered entrance animations
//
// Access Control:
//   - Department Overseers: Edit own department, view all read-only
//   - Event Overseers: Full access based on selected department
//

import SwiftUI

struct VolunteerListView: View {
    @StateObject private var viewModel = VolunteersViewModel()
    @ObservedObject private var sessionState = OverseerSessionState.shared
    @Environment(\.colorScheme) var colorScheme

    @State private var searchText = ""
    @State private var showCreateVolunteer = false
    @State private var selectedTab: VolunteerTab = .myDepartment
    @State private var hasAppeared = false
    @State private var volunteerToDelete: VolunteerListItem?
    @State private var showDeleteConfirmation = false

    enum VolunteerTab: String, CaseIterable {
        case myDepartment = "My Department"
        case allVolunteers = "All Volunteers"
    }

    var displayedVolunteers: [VolunteerListItem] {
        let source = selectedTab == .myDepartment
            ? viewModel.departmentVolunteers
            : viewModel.allVolunteers

        if searchText.isEmpty {
            return source
        }
        return source.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.congregation.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Can only create/edit volunteers in "My Department" mode
    var isEditable: Bool {
        selectedTab == .myDepartment
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker card
                tabPickerCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                // Content
                Group {
                    if viewModel.isLoading {
                        LoadingView(message: "Loading volunteers...")
                    } else if displayedVolunteers.isEmpty {
                        emptyState
                    } else {
                        volunteerList
                    }
                }
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("Volunteers")
            .searchable(text: $searchText, prompt: "Search by name or congregation")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if isEditable {
                        Button {
                            showCreateVolunteer = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateVolunteer) {
                CreateVolunteerSheet(viewModel: viewModel)
            }
            .refreshable {
                await loadVolunteers()
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
        .task {
            await loadVolunteers()
        }
        .onChange(of: sessionState.selectedDepartment?.id) { _, _ in
            Task { await loadVolunteers() }
        }
        .onChange(of: sessionState.claimedDepartment?.id) { _, _ in
            Task { await loadVolunteers() }
        }
        .onChange(of: selectedTab) { _, _ in
            Task { await loadVolunteers() }
        }
    }

    // MARK: - Tab Picker Card

    private var tabPickerCard: some View {
        Picker("Volunteer List", selection: $selectedTab) {
            ForEach(VolunteerTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, AppTheme.Spacing.screenEdge)
        .padding(.vertical, AppTheme.Spacing.m)
    }

    private func loadVolunteers() async {
        guard let eventId = sessionState.selectedEvent?.id else { return }

        switch selectedTab {
        case .myDepartment:
            let deptId = sessionState.selectedDepartment?.id
                ?? sessionState.claimedDepartment?.id
            await viewModel.loadDepartmentVolunteers(
                eventId: eventId,
                departmentId: deptId
            )
        case .allVolunteers:
            await viewModel.loadAllVolunteers(eventId: eventId)
        }
    }

    // MARK: - Volunteer List

    private var volunteerList: some View {
        List {
            ForEach(Array(displayedVolunteers.enumerated()), id: \.element.id) { index, volunteer in
                NavigationLink(destination: VolunteerDetailView(volunteer: volunteer, isEditable: isEditable)) {
                    VolunteerRowView(volunteer: volunteer, showDepartment: selectedTab == .allVolunteers, showChevron: false)
                }
                .buttonStyle(.plain)
                .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.02)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(
                    top: AppTheme.Spacing.s / 2,
                    leading: AppTheme.Spacing.screenEdge,
                    bottom: AppTheme.Spacing.s / 2,
                    trailing: AppTheme.Spacing.screenEdge
                ))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if isEditable {
                        Button(role: .destructive) {
                            volunteerToDelete = volunteer
                            showDeleteConfirmation = true
                            HapticManager.shared.lightTap()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(AppTheme.StatusColors.declined)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .confirmationDialog(
            "Delete Volunteer",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let volunteer = volunteerToDelete {
                    Task {
                        let success = await viewModel.deleteVolunteer(id: volunteer.id)
                        if success {
                            HapticManager.shared.success()
                        } else {
                            HapticManager.shared.error()
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                volunteerToDelete = nil
            }
        } message: {
            if let volunteer = volunteerToDelete {
                Text("Are you sure you want to permanently delete \(volunteer.fullName)? This will also remove all their assignments and check-in records.")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Spacer()

            Image(systemName: "person.3")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Text(selectedTab == .myDepartment ? "No Volunteers" : "No Event Volunteers")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text(selectedTab == .myDepartment
                ? "Tap + to add your first volunteer"
                : "No volunteers have been added to this event yet")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppTheme.Spacing.screenEdge)
    }
}

// MARK: - Volunteer Row View

struct VolunteerRowView: View {
    @Environment(\.colorScheme) var colorScheme

    let volunteer: VolunteerListItem
    var showDepartment: Bool = false
    var showChevron: Bool = true

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Avatar with initials
            ZStack {
                Circle()
                    .fill(departmentColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                Circle()
                    .strokeBorder(departmentColor.opacity(0.3), lineWidth: 1)
                    .frame(width: 48, height: 48)

                Text(volunteer.initials)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(departmentColor)
            }

            // Details
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(volunteer.fullName)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Text(volunteer.congregation)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                    if showDepartment, let dept = volunteer.departmentName {
                        Circle()
                            .fill(AppTheme.textTertiary(for: colorScheme))
                            .frame(width: 3, height: 3)

                        Text(dept)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(departmentColor)
                    }
                }
            }

            Spacer()

            // Chevron (hidden when inside List+NavigationLink which provides its own)
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private var departmentColor: Color {
        if let type = volunteer.departmentType {
            return DepartmentColor.color(for: type)
        }
        return AppTheme.themeColor
    }
}

// MARK: - Volunteer List Item Extensions

extension VolunteerListItem {
    var initials: String {
        let names = fullName.split(separator: " ")
        if names.count >= 2 {
            return String(names[0].prefix(1) + names[1].prefix(1)).uppercased()
        }
        return String(fullName.prefix(2)).uppercased()
    }
}

#Preview {
    VolunteerListView()
}

#Preview("Dark Mode") {
    VolunteerListView()
        .preferredColorScheme(.dark)
}
