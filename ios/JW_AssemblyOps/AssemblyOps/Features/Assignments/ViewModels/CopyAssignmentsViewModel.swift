//
//  CopyAssignmentsViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/16/26.
//

// MARK: - Copy Assignments View Model
//
// Manages the multi-step copy assignments flow:
//   1. Select target session
//   2. Select areas/posts to copy
//   3. Configure options (force assign, captain flags, etc.)
//   4. Execute copy and display results
//
// Uses CoverageMatrixViewModel data for source assignment counts
// and AreaManagementViewModel for area/post selection.
//
// Used by: CopyAssignmentsSheet

import Foundation
import Combine
import Apollo

@MainActor
final class CopyAssignmentsViewModel: ObservableObject {
    // Source context
    let sourceSession: EventSessionItem

    // Target selection
    @Published var targetSession: CoverageSession?
    @Published var availableSessions: [CoverageSession] = []

    // Area/post selection
    @Published var areas: [AreaItem] = []
    @Published var selectedAreaIds: Set<String> = []
    @Published var selectAll = false

    // Options
    @Published var forceAssign = false
    @Published var copyCanCount = true
    @Published var copyIsCaptain = false
    @Published var copyAreaCaptains = false

    // State
    @Published var isLoading = false
    @Published var error: String?
    @Published var result: CopyResult?

    init(sourceSession: EventSessionItem) {
        self.sourceSession = sourceSession
    }

    /// Number oThf source assignments for the selected areas/posts
    func sourceAssignmentCount(from coverageVM: CoverageMatrixViewModel) -> Int {
        let sourceSlots = coverageVM.slots.filter { $0.sessionId == sourceSession.id }
        let selectedPosts = postsInSelectedAreas
        let postIds = Set(selectedPosts.map(\.id))
        return sourceSlots
            .filter { postIds.contains($0.postId) }
            .reduce(0) { $0 + $1.assignments.count }
    }

    /// Posts within selected areas
    var postsInSelectedAreas: [AreaPostItem] {
        areas
            .filter { selectedAreaIds.contains($0.id) }
            .flatMap(\.posts)
    }

    /// Load available sessions from coverage data (excludes source session)
    func loadSessions(from coverageVM: CoverageMatrixViewModel) {
        availableSessions = coverageVM.sessions.filter { $0.id != sourceSession.id }
    }

    /// Load areas from area view model
    func loadAreas(from areaVM: AreaManagementViewModel) {
        areas = areaVM.areas
    }

    func toggleArea(_ areaId: String) {
        if selectedAreaIds.contains(areaId) {
            selectedAreaIds.remove(areaId)
        } else {
            selectedAreaIds.insert(areaId)
        }
        selectAll = selectedAreaIds.count == areas.count
    }

    func toggleSelectAll() {
        if selectAll {
            selectedAreaIds.removeAll()
            selectAll = false
        } else {
            selectedAreaIds = Set(areas.map(\.id))
            selectAll = true
        }
    }

    var canExecute: Bool {
        targetSession != nil && !selectedAreaIds.isEmpty && !isLoading
    }

    func executeCopy(departmentId: String) async {
        guard let targetSession = targetSession else { return }
        guard !selectedAreaIds.isEmpty else { return }

        isLoading = true
        error = nil

        let input = AssemblyOpsAPI.CopySessionAssignmentsInput(
            sourceSessionId: sourceSession.id,
            targetSessionId: targetSession.id,
            departmentId: departmentId,
            areaIds: .some(Array(selectedAreaIds)),
            postIds: .none,
            copyIsCaptain: .some(copyIsCaptain),
            copyCanCount: .some(copyCanCount),
            copyAreaCaptains: .some(copyAreaCaptains),
            forceAssign: .some(forceAssign)
        )

        do {
            let data = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AssemblyOpsAPI.CopySessionAssignmentsMutation.Data.CopySessionAssignments, Error>) in
                NetworkClient.shared.apollo.perform(
                    mutation: AssemblyOpsAPI.CopySessionAssignmentsMutation(input: input)
                ) { result in
                    switch result {
                    case .success(let graphQLResult):
                        if let data = graphQLResult.data?.copySessionAssignments {
                            continuation.resume(returning: data)
                        } else if let errors = graphQLResult.errors, !errors.isEmpty {
                            continuation.resume(throwing: NSError(
                                domain: "CopyAssignments",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Unknown error"]
                            ))
                        } else {
                            continuation.resume(throwing: NSError(
                                domain: "CopyAssignments",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to copy assignments"]
                            ))
                        }
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }

            result = CopyResult(
                copiedCount: data.copiedCount,
                skippedCount: data.skippedCount,
                skippedVolunteers: data.skippedVolunteers.map {
                    SkippedVolunteer(volunteerName: $0.volunteerName, postName: $0.postName, reason: $0.reason)
                },
                copiedAreaCaptains: data.copiedAreaCaptains
            )

            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }

        isLoading = false
    }
}

// MARK: - Result Models

struct CopyResult {
    let copiedCount: Int
    let skippedCount: Int
    let skippedVolunteers: [SkippedVolunteer]
    let copiedAreaCaptains: Int

    var hasSkipped: Bool { skippedCount > 0 }
}

struct SkippedVolunteer: Identifiable {
    var id: String { "\(volunteerName)-\(postName)" }
    let volunteerName: String
    let postName: String
    let reason: String
}
