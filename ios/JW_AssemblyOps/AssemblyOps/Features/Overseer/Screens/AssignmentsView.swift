//
//  AssignmentsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Assignments View (Overseer)
//
// Coverage matrix view for overseers to manage volunteer scheduling.
// Uses the app's design system with warm background and refined cells.
//
// Features:
//   - Warm gradient background
//   - Scrollable grid: Posts (rows) x Sessions (columns)
//   - Themed coverage cells with status colors
//   - Filter menu: Show all, gaps only, or filled only
//   - Tap cell to open SlotDetailSheet for assignment management
//   - Pull-to-refresh for coverage data
//   - Entrance animations
//
// Components:
//   - matrixContent: LazyVGrid displaying the coverage matrix
//   - headerRow: Session name headers in themed cards
//   - postRow: Post name + slot cells for each session
//   - emptyState: Styled empty state when no coverage data exists
//

import SwiftUI

struct AssignmentsView: View {
    @StateObject private var viewModel = CoverageMatrixViewModel()
    @ObservedObject private var sessionState = OverseerSessionState.shared
    @Environment(\.colorScheme) var colorScheme

    @State private var selectedSlot: CoverageSlot?
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Warm background
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()

                Group {
                    if viewModel.isLoading {
                        LoadingView(message: "Loading coverage...")
                    } else if viewModel.slots.isEmpty {
                        emptyState
                    } else {
                        matrixContent
                    }
                }
            }
            .navigationTitle("Assignments")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
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

                        Divider()

                        NavigationLink {
                            DeclinedAssignmentsView()
                        } label: {
                            Label("Declined Assignments", systemImage: "xmark.circle")
                        }
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
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
        .task {
            if let departmentId = sessionState.selectedDepartment?.id {
                viewModel.departmentId = departmentId
                await viewModel.loadCoverage()
            }
        }
    }

    // MARK: - Matrix Content

    private var matrixContent: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                // Header row
                headerRow
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                // Data rows
                ForEach(Array(viewModel.posts.enumerated()), id: \.element.id) { index, post in
                    postRow(post)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.02)
                }
            }
            .padding(AppTheme.Spacing.screenEdge)
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            // Post column header
            Text("Post")
                .font(AppTheme.Typography.captionBold)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .frame(width: 120, alignment: .leading)
                .padding(.vertical, AppTheme.Spacing.s)
                .padding(.horizontal, AppTheme.Spacing.s)

            // Session headers
            ForEach(viewModel.sessions, id: \.id) { session in
                VStack(spacing: 2) {
                    Text(session.name)
                        .font(AppTheme.Typography.captionBold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(formatTime(session.startTime))
                        .font(AppTheme.Typography.captionSmall)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
                .frame(width: 80)
                .padding(.vertical, AppTheme.Spacing.s)
                .background(AppTheme.cardBackground(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
            }
        }
    }

    // MARK: - Post Row

    @ViewBuilder
    private func postRow(_ post: CoveragePost) -> some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            // Post name
            Text(post.name)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(width: 120, alignment: .leading)
                .padding(.vertical, AppTheme.Spacing.s)
                .padding(.horizontal, AppTheme.Spacing.s)
                .background(AppTheme.cardBackground(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

            // Coverage cells
            ForEach(viewModel.sessions, id: \.id) { session in
                if let slot = viewModel.slot(for: post.id, session: session.id) {
                    CoverageCell(slot: slot, colorScheme: colorScheme) {
                        selectedSlot = slot
                    }
                } else {
                    Color.clear
                        .frame(width: 80, height: 56)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Spacer()

            Image(systemName: "tablecells")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Text("No Assignments Data")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("Create posts and sessions first")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppTheme.Spacing.screenEdge)
        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Coverage Cell

struct CoverageCell: View {
    let slot: CoverageSlot
    let colorScheme: ColorScheme
    let onTap: () -> Void

    private var statusColor: Color {
        if slot.isFilled {
            return AppTheme.StatusColors.accepted
        } else if slot.filled > 0 {
            return AppTheme.StatusColors.warning
        } else {
            return AppTheme.StatusColors.declined
        }
    }

    private var backgroundColor: Color {
        if slot.isFilled {
            return AppTheme.StatusColors.acceptedBackground
        } else if slot.filled > 0 {
            return AppTheme.StatusColors.warningBackground
        } else {
            return AppTheme.StatusColors.declinedBackground
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Fill ratio
                Text("\(slot.filled)/\(slot.capacity)")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(statusColor)

                // First volunteer name
                if !slot.assignments.isEmpty {
                    Text(slot.assignments.first?.volunteer.lastName ?? "")
                        .font(AppTheme.Typography.captionSmall)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .lineLimit(1)
                }
            }
            .frame(width: 80, height: 56)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .strokeBorder(statusColor.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
        .buttonStyle(CoverageCellButtonStyle())
    }
}

// MARK: - Coverage Cell Button Style

struct CoverageCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    AssignmentsView()
}

#Preview("Dark Mode") {
    AssignmentsView()
        .preferredColorScheme(.dark)
}
