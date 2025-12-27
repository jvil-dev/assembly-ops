//
//  AssignmentsListView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//


import SwiftUI

struct AssignmentsListView: View {
    @StateObject private var viewModel = AssignmentsViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && !viewModel.hasLoaded {
                    LoadingView(message: "Loading schedule...")
                } else if let error = viewModel.errorMessage, viewModel.isEmpty {
                    ErrorView(message: error) {
                        viewModel.refresh()
                    }
                } else if viewModel.isEmpty {
                    EmptyAssignmentsView()
                } else {
                    assignmentsList
                }
            }
            .navigationTitle("My Schedule")
            .refreshable {
                viewModel.refresh()
                try? await Task.sleep(for: .seconds(0.5))
            }
            .task {
                if !viewModel.hasLoaded {
                    viewModel.fetchAssignments()
                }
            }
        }
    }
    
    private var assignmentsList: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
                ForEach(viewModel.groupedAssignments, id: \.date) { group in
                    Section {
                        ForEach(group.assignments) { assignment in
                            NavigationLink(value: assignment) {
                                AssignmentCardView(assignment: assignment)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        dateHeader(for: group.date)
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.systemGroupedBackground))
        .navigationDestination(for: Assignment.self) { assignment in
            AssignmentDetailView(assignment: assignment)
        }
    }
    
    private func dateHeader(for date: Date) -> some View {
        HStack {
            if Calendar.current.isDateInToday(date) {
                Text("Today")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("- \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if Calendar.current.isDateInTomorrow(date) {
                Text("Tomorrow")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("- \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(date.formatted(date: .complete, time: .omitted))
                    .font(.headline)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Hashable Conformance for Navigation
extension Assignment: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Assignment, rhs: Assignment) -> Bool {
        lhs.id == rhs.id
    }
}

#Preview {
    AssignmentsListView()
}
