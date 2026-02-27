//
//  CoverageMatrixViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Coverage Matrix View Model
//
// Manages the department coverage matrix data for overseer scheduling views.
// Fetches slot data from DepartmentCoverageQuery and organizes by post/session.
//
// Properties:
//   - slots: All coverage slots (post + session combinations)
//   - posts: Unique posts sorted alphabetically
//   - sessions: Unique sessions sorted by start time
//   - filter: Current filter (all, gaps, filled)
//   - departmentId: Target department for queries
//
// Types:
//   - CoverageFilter: Enum for filtering slots (all, gaps only, filled only)
//
// Methods:
//   - loadCoverage(): Fetch department coverage from GraphQL API
//   - slot(for:session:): Get specific slot by post and session ID
//   - filteredSlots: Computed property applying current filter
//
// Data Flow:
//   1. Set departmentId before calling loadCoverage()
//   2. Query returns flat list of slots with nested post/session/assignment data
//   3. ViewModel extracts unique posts and sessions into sorted arrays
//   4. Views use slot(for:session:) to build matrix grid
//

import Foundation
import Combine
import Apollo

@MainActor
final class CoverageMatrixViewModel: ObservableObject {
    @Published var slots: [CoverageSlot] = []
    @Published var posts: [CoveragePost] = []
    @Published var sessions: [CoverageSession] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var filter: CoverageFilter = .all

    var departmentId: String?

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    enum CoverageFilter {
        case all
        case gaps
        case filled
    }

    func loadCoverage() async {
        guard let departmentId = departmentId else { return }

        isLoading = true
        error = nil

        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.DepartmentCoverageQuery(departmentId: departmentId),
                cachePolicy: .fetchIgnoringCacheData
            )

            guard let data = result.data?.departmentCoverage else {
                error = "Failed to load coverage data"
                isLoading = false
                return
            }

            // Extract unique posts and sessions
            var postsDict: [String: CoveragePost] = [:]
            var sessionsDict: [String: CoverageSession] = [:]
            var mappedSlots: [CoverageSlot] = []

            for slot in data {
                // Build post
                let post = slot.post
                if postsDict[post.id] == nil {
                    postsDict[post.id] = CoveragePost(
                        id: post.id,
                        name: post.name,
                        capacity: post.capacity,
                        category: post.category,
                        location: post.location,
                        sortOrder: post.sortOrder,
                        areaId: post.areaId,
                        areaName: post.areaName
                    )
                }

                // Build session
                let session = slot.session
                if sessionsDict[session.id] == nil {
                    sessionsDict[session.id] = CoverageSession(
                        id: session.id,
                        name: session.name,
                        date: parseDate(session.date) ?? Date(),
                        startTime: parseDate(session.startTime) ?? Date(),
                        endTime: parseDate(session.endTime) ?? Date()
                    )
                }

                // Build slot with assignments
                let assignments = slot.assignments.map { assignment in
                    CoverageAssignment(
                        id: assignment.id,
                        volunteer: CoverageVolunteer(
                            id: assignment.volunteer.id,
                            firstName: assignment.volunteer.firstName,
                            lastName: assignment.volunteer.lastName
                        ),
                        checkIn: assignment.checkIn.map { checkIn in
                            CoverageCheckInInfo(
                                id: checkIn.id,
                                checkInTime: parseDate(checkIn.checkInTime) ?? Date()
                            )
                        },
                        status: mapStatus(assignment.status),
                        forceAssigned: assignment.forceAssigned
                    )
                }

                let coverageSlot = CoverageSlot(
                    postId: post.id,
                    sessionId: session.id,
                    postName: post.name,
                    sessionName: session.name,
                    assignments: assignments,
                    filled: slot.filled,
                    capacity: slot.capacity,
                    isFilled: slot.isFilled
                )
                mappedSlots.append(coverageSlot)
            }

            // Sort posts by category → sortOrder → name
            posts = postsDict.values.sorted {
                let cat0 = $0.category ?? ""
                let cat1 = $1.category ?? ""
                if cat0 != cat1 { return cat0 < cat1 }
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.name < $1.name
            }

            // Sort sessions by date/time
            sessions = sessionsDict.values.sorted { $0.startTime < $1.startTime }

            slots = mappedSlots

        } catch {
            self.error = "Network error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func slot(for postId: String, session sessionId: String) -> CoverageSlot? {
        slots.first { $0.postId == postId && $0.sessionId == sessionId }
    }

    /// All slots for a specific session
    func slots(for sessionId: String) -> [CoverageSlot] {
        let sessionSlots = slots.filter { $0.sessionId == sessionId }
        switch filter {
        case .all:
            return sessionSlots
        case .gaps:
            return sessionSlots.filter { !$0.isFilled }
        case .filled:
            return sessionSlots.filter { $0.isFilled }
        }
    }

    var filteredSlots: [CoverageSlot] {
        switch filter {
        case .all:
            return slots
        case .gaps:
            return slots.filter { !$0.isFilled }
        case .filled:
            return slots.filter { $0.isFilled }
        }
    }

    // MARK: - Suggestions

    var existingCategories: [String] {
        Array(Set(posts.compactMap { $0.category?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }))
            .sorted()
    }

    var existingLocations: [String] {
        Array(Set(posts.compactMap { $0.location?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }))
            .sorted()
    }

    // MARK: - Helpers

    private func parseDate(_ dateString: String) -> Date? {
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
        // Try without fractional seconds
        let fallbackFormatter = ISO8601DateFormatter()
        return fallbackFormatter.date(from: dateString)
    }

    private func mapStatus(_ raw: GraphQLEnum<AssemblyOpsAPI.AssignmentStatus>) -> AssignmentStatus {
        switch raw.value {
        case .pending: return .pending
        case .accepted: return .accepted
        case .declined: return .declined
        case .autoDeclined: return .autoDeclined
        case .none: return .pending
        }
    }
}
