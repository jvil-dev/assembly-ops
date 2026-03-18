//
//  CaptainVolunteerPickerSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/1/26.
//

// MARK: - Captain Volunteer Picker Sheet
//
// Modal for captains to select volunteers for shift assignment.
// Uses captain-scoped mutation (captainCreateAssignment) instead of
// overseer-level mutations.
//
// Features:
//   - Search/filter volunteers by name
//   - Single-select volunteer
//   - Creates assignment via captainCreateAssignment mutation
//   - Department-themed accent color
//

import SwiftUI
import Apollo

struct CaptainVolunteerPickerSheet: View {
    let eventId: String
    let postId: String
    let sessionId: String
    let shiftId: String
    let departmentType: String
    let volunteers: [CaptainVolunteerItem]
    @ObservedObject var viewModel: CaptainSchedulingViewModel
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var searchText = ""
    @State private var selectedVolunteerId: String?
    @State private var isAssigning = false
    @State private var canCount = false
    @State private var showError = false
    @State private var assignedVolunteerIds: Set<String> = []

    private var accentColor: Color {
        DepartmentColor.color(for: departmentType)
    }

    private var filteredVolunteers: [CaptainVolunteerItem] {
        if searchText.isEmpty {
            return volunteers
        }
        return volunteers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if volunteers.isEmpty {
                    emptyState
                } else {
                    volunteerList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .themedBackground(scheme: colorScheme)
            .searchable(text: $searchText, prompt: "captain.scheduling.searchVolunteers".localized)
            .navigationTitle("captain.scheduling.selectVolunteer".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isAssigning {
                        ProgressView()
                    } else {
                        Button("captain.scheduling.assign".localized) {
                            Task { await assignVolunteer() }
                        }
                        .disabled(selectedVolunteerId == nil)
                        .fontWeight(.semibold)
                    }
                }
            }
            .alert("common.error".localized, isPresented: $showError) {
                Button("common.ok".localized) { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .onChange(of: viewModel.error) { _, newValue in
                showError = newValue != nil
            }
            .task {
                await loadSessionAssignmentCounts()
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
            Text("captain.scheduling.noVolunteers".localized)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)
            Text("captain.scheduling.noVolunteersHint".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(AppTheme.Spacing.screenEdge)
    }

    // MARK: - Volunteer List

    private var volunteerList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.m) {
                canCountCard

                ForEach(filteredVolunteers) { volunteer in
                    let isSelected = selectedVolunteerId == volunteer.id
                    Button {
                        HapticManager.shared.lightTap()
                        withAnimation(AppTheme.quickAnimation) {
                            selectedVolunteerId = isSelected ? nil : volunteer.id
                        }
                    } label: {
                        HStack(spacing: AppTheme.Spacing.m) {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? accentColor.opacity(0.15) : AppTheme.cardBackgroundSecondary(for: colorScheme))
                                    .frame(width: 44, height: 44)
                                Text(initials(for: volunteer.name))
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(isSelected ? accentColor : AppTheme.textSecondary(for: colorScheme))
                            }

                            HStack(spacing: 4) {
                                Text(volunteer.name)
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(.primary)

                                if assignedVolunteerIds.contains(volunteer.id) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(AppTheme.StatusColors.warning)
                                }
                            }

                            Spacer()

                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundStyle(isSelected ? accentColor : AppTheme.textTertiary(for: colorScheme))
                        }
                        .cardPadding()
                        .themedCard(scheme: colorScheme)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .strokeBorder(isSelected ? accentColor.opacity(0.3) : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.s)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }

    // MARK: - Can Count Card

    private var canCountCard: some View {
        Toggle(isOn: $canCount) {
            VStack(alignment: .leading, spacing: 2) {
                Text("assignment.canCount.toggle".localized)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundStyle(.primary)
                Text("assignment.canCount.subtitle".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .tint(accentColor)
        .onChange(of: canCount) {
            HapticManager.shared.lightTap()
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Load Session Assignment Counts

    private func loadSessionAssignmentCounts() async {
        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.SessionAssignmentCountsQuery(sessionId: sessionId),
                cachePolicy: .fetchIgnoringCacheData
            )
            if let data = result.data?.sessionAssignments {
                var ids = Set<String>()
                for assignment in data {
                    if let volId = assignment.volunteer?.id {
                        ids.insert(volId)
                    }
                }
                assignedVolunteerIds = ids
            }
        } catch {
            // Non-critical
        }
    }

    // MARK: - Assign Volunteer

    private func assignVolunteer() async {
        guard let volunteerId = selectedVolunteerId else { return }
        isAssigning = true

        await viewModel.createAssignment(
            eventId: eventId,
            eventVolunteerId: volunteerId,
            postId: postId,
            sessionId: sessionId,
            shiftId: shiftId,
            canCount: canCount
        )

        isAssigning = false

        if viewModel.error == nil {
            onComplete()
            dismiss()
        }
    }

    // MARK: - Helpers

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }
}

#Preview {
    CaptainVolunteerPickerSheet(
        eventId: "1",
        postId: "p1",
        sessionId: "s1",
        shiftId: "sh1",
        departmentType: "ATTENDANT",
        volunteers: [
            CaptainVolunteerItem(id: "1", name: "John Doe"),
            CaptainVolunteerItem(id: "2", name: "Jane Smith"),
        ],
        viewModel: CaptainSchedulingViewModel()
    ) {}
}
