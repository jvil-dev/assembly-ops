//
//  CaptainSchedulingViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/1/26.
//

// MARK: - Captain Scheduling View Model
//
// Manages captain scheduling operations: assignments and shifts.
// Captains can create/delete assignments, swap volunteers, and manage shifts
// within their attendant department.
//
// Uses captain-scoped queries (captainSessions, captainShifts, etc.)
// that require the captain guard instead of overseer auth.
//

import Foundation
import Combine
import Apollo

@MainActor
final class CaptainSchedulingViewModel: ObservableObject {
    @Published var shifts: [ShiftItem] = []
    @Published var sessions: [EventSessionItem] = []
    @Published var selectedSession: EventSessionItem?
    @Published var volunteers: [CaptainVolunteerItem] = []
    @Published var posts: [CaptainPostItem] = []
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Load Sessions

    func loadSessions(eventId: String) async {
        isLoading = true
        error = nil

        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.CaptainSessionsQuery(eventId: eventId),
                cachePolicy: .fetchIgnoringCacheData
            )

            guard let data = result.data?.captainSessions else {
                error = "Failed to load sessions"
                isLoading = false
                return
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let fallback = ISO8601DateFormatter()

            sessions = data.map { session in
                EventSessionItem(
                    id: session.id,
                    name: session.name,
                    date: formatter.date(from: session.date) ?? fallback.date(from: session.date) ?? Date(),
                    startTime: formatter.date(from: session.startTime) ?? fallback.date(from: session.startTime) ?? Date(),
                    assignmentCount: session.assignmentCount
                )
            }

            if selectedSession == nil, let first = sessions.first {
                selectedSession = first
                await loadShifts(sessionId: first.id)
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Load Shifts

    func loadShifts(sessionId: String) async {
        error = nil

        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.CaptainShiftsQuery(sessionId: sessionId, postId: .none),
                cachePolicy: .fetchIgnoringCacheData
            )

            if let data = result.data?.captainShifts {
                shifts = data.map { ShiftItem(fromCaptain: $0) }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Load Volunteers

    func loadVolunteers(eventId: String, departmentId: String) async {
        error = nil

        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.CaptainVolunteersQuery(
                    eventId: eventId,
                    departmentId: departmentId
                ),
                cachePolicy: .fetchIgnoringCacheData
            )

            if let data = result.data?.captainVolunteers {
                volunteers = data.map { vol in
                    CaptainVolunteerItem(
                        id: vol.id,
                        name: "\(vol.user.firstName) \(vol.user.lastName)"
                    )
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Load Posts

    func loadPosts(departmentId: String) async {
        error = nil

        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.CaptainPostsQuery(departmentId: departmentId),
                cachePolicy: .fetchIgnoringCacheData
            )

            if let data = result.data?.captainPosts {
                posts = data.map { post in
                    CaptainPostItem(id: post.id, name: post.name)
                }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Captain Assignment Operations

    func createAssignment(eventId: String, eventVolunteerId: String, postId: String, sessionId: String, shiftId: String?, canCount: Bool = false) async {
        isLoading = true
        error = nil

        do {
            let input = AssemblyOpsAPI.CaptainCreateAssignmentInput(
                eventId: eventId,
                eventVolunteerId: eventVolunteerId,
                postId: postId,
                sessionId: sessionId,
                shiftId: shiftId.map { .some($0) } ?? .none,
                canCount: .some(canCount)
            )
            let _ = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.CaptainCreateAssignmentMutation(input: input)
            )
            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }

        isLoading = false
    }

    func deleteAssignment(eventId: String, assignmentId: String) async {
        error = nil

        do {
            let _ = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.CaptainDeleteAssignmentMutation(
                    eventId: eventId,
                    assignmentId: assignmentId
                )
            )
            // Remove from local shift assignments
            for i in shifts.indices {
                shifts[i].assignments.removeAll { $0.id == assignmentId }
            }
            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }

    func swapVolunteer(assignmentId: String, newVolunteerId: String, eventId: String) async {
        isLoading = true
        error = nil

        do {
            let input = AssemblyOpsAPI.CaptainSwapInput(
                assignmentId: assignmentId,
                newEventVolunteerId: newVolunteerId
            )
            let _ = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.CaptainSwapVolunteerMutation(
                    input: input,
                    eventId: eventId
                )
            )
            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }

        isLoading = false
    }

    // MARK: - Captain Shift Operations

    func createShift(eventId: String, sessionId: String, postId: String, startTime: String, endTime: String) async {
        isLoading = true
        error = nil

        do {
            let input = AssemblyOpsAPI.CaptainCreateShiftInput(
                eventId: eventId,
                sessionId: sessionId,
                postId: postId,
                startTime: startTime,
                endTime: endTime
            )
            let result = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.CaptainCreateShiftMutation(input: input)
            )

            if let data = result.data?.captainCreateShift {
                let creatorName: String? = {
                    if let creator = data.createdBy {
                        return "\(creator.firstName) \(creator.lastName)"
                    }
                    return nil
                }()
                let newShift = ShiftItem(
                    id: data.id,
                    sessionId: data.session.id,
                    postId: data.post.id,
                    name: data.name,
                    startTime: data.startTime,
                    endTime: data.endTime,
                    sessionName: data.session.name,
                    postName: data.post.name,
                    createdAt: nil,
                    createdByName: creatorName,
                    assignments: []
                )
                shifts.append(newShift)
                shifts.sort { $0.startTime < $1.startTime }
            }

            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }

        isLoading = false
    }

    func deleteShift(id: String, eventId: String) async {
        error = nil

        do {
            let _ = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.CaptainDeleteShiftMutation(id: id, eventId: eventId)
            )
            shifts.removeAll { $0.id == id }
            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }
}

// MARK: - Captain Supporting Types

struct CaptainVolunteerItem: Identifiable {
    let id: String
    let name: String
}

struct CaptainPostItem: Identifiable {
    let id: String
    let name: String
}
