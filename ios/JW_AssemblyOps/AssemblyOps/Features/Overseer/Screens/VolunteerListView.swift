//
//  VolunteerListView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Volunteer List View
//
// Main volunteer management screen for overseers.
// Supports viewing department volunteers and full event roster.
//
// Tabs:
//   - My Department: Editable list of volunteers in overseer's department
//   - All Volunteers: Read-only view of entire event roster
//
// Features:
//   - Search by name or congregation
//   - Add new volunteers (My Department tab only)
//   - Segmented picker for tab switching
//   - CreateVolunteerSheet for adding new volunteers
//
// Access Control:
//   - Department Overseers: Edit own department, view all read-only
//   - Event Overseers: Full access based on selected department
//
// Properties:
//   - displayedVolunteers: Filtered list based on tab and search
//   - isEditable: True when in My Department tab
//

import SwiftUI

struct VolunteerListView: View {
    @StateObject private var viewModel = VolunteersViewModel()
    @ObservedObject private var sessionState = OverseerSessionState.shared
    @State private var searchText = ""
    @State private var showCreateVolunteer = false
    @State private var selectedTab: VolunteerTab = .myDepartment

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
                // Tab picker
                Picker("Volunteer List", selection: $selectedTab) {
                    ForEach(VolunteerTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Volunteer list
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if displayedVolunteers.isEmpty {
                        emptyState
                    } else {
                        volunteerList
                    }
                }
            }
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
        }
        .task {
            await loadVolunteers()
        }
        .onChange(of: sessionState.selectedDepartment?.id) { _, _ in
            Task { await loadVolunteers() }
        }
        .onChange(of: selectedTab) { _, _ in
            Task { await loadVolunteers() }
        }
    }

    private func loadVolunteers() async {
        guard let eventId = sessionState.selectedEvent?.id else { return }

        switch selectedTab {
        case .myDepartment:
            await viewModel.loadDepartmentVolunteers(
                eventId: eventId,
                departmentId: sessionState.selectedDepartment?.id
            )
        case .allVolunteers:
            await viewModel.loadAllVolunteers(eventId: eventId)
        }
    }

    private var volunteerList: some View {
        List(displayedVolunteers) { volunteer in
            NavigationLink(destination: VolunteerDetailView(volunteer: volunteer, isEditable: isEditable)) {
                VolunteerRowView(volunteer: volunteer, showDepartment: selectedTab == .allVolunteers)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            selectedTab == .myDepartment ? "No Volunteers" : "No Event Volunteers",
            systemImage: "person.3",
            description: Text(selectedTab == .myDepartment
                ? "Tap + to add your first volunteer"
                : "No volunteers have been added to this event yet")
        )
    }
}

struct VolunteerRowView: View {
    let volunteer: VolunteerListItem
    var showDepartment: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(volunteer.fullName)
                .font(.headline)
            HStack {
                Text(volunteer.congregation)
                if showDepartment, let dept = volunteer.departmentName {
                    Text("•")
                    Text(dept)
                        .foregroundStyle(Color("ThemeColor"))
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

