//
//  AssignmentsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Assignments View (Overseer)
//
// Coverage matrix view for overseers to manage volunteer scheduling.
// Displays posts vs sessions grid showing assignment fill status.
//
// Features:
//   - Scrollable grid: Posts (rows) x Sessions (columns)
//   - Color-coded cells: Green (filled), Red (gaps), Gray (partial)
//   - Filter menu: Show all, gaps only, or filled only
//   - Tap cell to open SlotDetailSheet for assignment management
//   - Pull-to-refresh for coverage data
//
// Components:
//   - matrixContent: LazyVGrid displaying the coverage matrix
//   - headerRow: Session name headers
//   - postRow: Post name + slot cells for each session
//   - emptyState: Shown when no coverage data exists
//
// Data Flow:
//   1. On appear: Sets departmentId from OverseerSessionState
//   2. Loads coverage via CoverageMatrixViewModel.loadCoverage()
//   3. User taps cell → SlotDetailSheet for volunteer assignment
//

import SwiftUI

struct AssignmentsView: View {
    @StateObject private var viewModel = CoverageMatrixViewModel()
    @ObservedObject private var sessionState = OverseerSessionState.shared
    @State private var selectedSlot: CoverageSlot?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.slots.isEmpty {
                    emptyState
                } else {
                    matrixContent
                }
            }
            .navigationTitle("Assignments")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Show All") { viewModel.filter = .all }
                        Button("Gaps Only") { viewModel.filter = .gaps }
                        Button("Filled Only") { viewModel.filter = .filled }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(item: $selectedSlot) { slot in
                SlotDetailSheet(slot: slot, viewModel: viewModel)
            }
            .refreshable {
                await viewModel.loadCoverage()
            }
        }
        .task {
            if let departmentId = sessionState.selectedDepartment?.id {
                viewModel.departmentId = departmentId
                await viewModel.loadCoverage()
            }
        }
    }

    private var matrixContent: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVGrid(columns: gridColumns, spacing: 2) {
                // Header row - session names
                headerRow

                // Data rows - one per post
                ForEach(viewModel.posts, id: \.id) { post in
                    postRow(post)
                }
            }
            .padding()
        }
    }

    private var gridColumns: [GridItem] {
        var columns: [GridItem] = [.init(.fixed(120), alignment: .leading)]
        columns += viewModel.sessions.map { _ in .init(.fixed(80)) }
        return columns
    }

    private var headerRow: some View {
        Group {
            Text("Post")
                .font(.caption)
                .fontWeight(.semibold)

            ForEach(viewModel.sessions, id: \.id) { session in
                VStack(spacing: 2) {
                    Text(session.name)
                        .font(.caption2)
                        .fontWeight(.semibold)
                    Text(formatTime(session.startTime))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func postRow(_ post: CoveragePost) -> some View {
        Text(post.name)
            .font(.caption)
            .lineLimit(2)

        ForEach(viewModel.sessions, id: \.id) { session in
            if let slot = viewModel.slot(for: post.id, session: session.id) {
                CoverageCell(slot: slot) {
                    selectedSlot = slot
                }
            } else {
                Color.clear
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Assignments Data",
            systemImage: "tablecells",
            description: Text("Create posts and sessions first")
        )
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct CoverageCell: View {
    let slot: CoverageSlot
    let onTap: () -> Void

    private var backgroundColor: Color {
        if slot.isFilled {
            return .green.opacity(0.3)
        } else if slot.filled > 0 {
            return .yellow.opacity(0.3)
        } else {
            return .red.opacity(0.2)
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(slot.filled)/\(slot.capacity)")
                    .font(.caption)
                    .fontWeight(.medium)

                if !slot.assignments.isEmpty {
                    Text(slot.assignments.first?.volunteer.lastName ?? "")
                        .font(.caption2)
                        .lineLimit(1)
                }
            }
            .frame(width: 76, height: 50)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
