//
//  SessionSettingsViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/8/26.
//

// MARK: - Session Settings View Model
//
// Manages state for per-department session settings (start time, end time, notes).
// Loads existing DepartmentSession on open; saves via UpsertDepartmentSessionMutation.
//
// Published Properties:
//   - startTime / endTime: Department-specific times for this session
//   - notes: Optional notes for the department
//   - hasExistingSettings: Whether a DepartmentSession already exists
//
// Methods:
//   - load(sessionId:departmentId:): Fetch existing settings if any
//   - save(sessionId:departmentId:): Upsert department session settings

import Foundation
import Apollo
import Combine

private func utcDate(hour: Int, minute: Int = 0) -> Date {
    var comps = DateComponents()
    comps.timeZone = TimeZone(identifier: "UTC")
    comps.year = 1970; comps.month = 1; comps.day = 1
    comps.hour = hour; comps.minute = minute; comps.second = 0
    return Calendar(identifier: .gregorian).date(from: comps) ?? Date()
}

@MainActor
final class SessionSettingsViewModel: ObservableObject {
    @Published var startTime: Date
    @Published var endTime: Date

    init(sessionName: String = "") {
        let isAfternoon = sessionName.lowercased().contains("afternoon")
        startTime = isAfternoon ? utcDate(hour: 13) : utcDate(hour: 9)
        endTime   = isAfternoon ? utcDate(hour: 17) : utcDate(hour: 12)
    }
    @Published var notes: String = ""
    @Published var hasExistingSettings = false
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var didSave = false
    @Published var error: String?

    func load(sessionId: String, departmentId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.DepartmentSessionQuery(sessionId: sessionId, departmentId: departmentId),
                cachePolicy: .fetchIgnoringCacheData
            )
            guard let deptSession = result.data?.session?.departmentSession else { return }
            hasExistingSettings = true

            if let start = deptSession.startTime, let parsed = DateUtils.parseISO8601(start) {
                startTime = parsed
            }
            if let end = deptSession.endTime, let parsed = DateUtils.parseISO8601(end) {
                endTime = parsed
            }

            notes = deptSession.notes ?? ""
        } catch {
            // No existing settings — keep defaults, don't show error
        }
    }

    func save(sessionId: String, departmentId: String) async {
        isSaving = true
        error = nil
        defer { isSaving = false }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.timeZone = TimeZone(identifier: "UTC")

        let startString = timeFormatter.string(from: startTime)
        let endString = timeFormatter.string(from: endTime)

        let input = AssemblyOpsAPI.UpsertDepartmentSessionInput(
            startTime: .some(startString),
            endTime: .some(endString),
            notes: notes.isEmpty ? .none : .some(notes)
        )

        do {
            _ = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.UpsertDepartmentSessionMutation(
                    departmentId: departmentId,
                    sessionId: sessionId,
                    input: input
                )
            )
            HapticManager.shared.success()
            didSave = true
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }
}
