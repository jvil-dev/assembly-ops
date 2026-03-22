//
//  CaptainAttendanceViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/1/26.
//

// MARK: - Captain Attendance View Model
//
// Loads attendance counts for all posts in the captain's assigned areas.
// Uses the captainAreaAttendanceCounts query.
//
// Published:
//   - counts: grouped attendance count items
//   - isLoading, error
//
// Methods:
//   - load(eventId:): Fetch captain's area attendance counts

import Foundation
import Combine
import Apollo

struct CaptainAttendanceCountItem: Identifiable {
    let id: String
    let postId: String
    let postName: String
    let postLocation: String?
    let areaId: String?
    let areaName: String?
    let sessionId: String
    let sessionName: String
    let sessionDate: Date
    let count: Int
    let section: String?
    let notes: String?
    let submittedByName: String
    let submittedAt: Date
}

@MainActor
final class CaptainAttendanceViewModel: ObservableObject {
    @Published var counts: [CaptainAttendanceCountItem] = []
    @Published var isLoading = false
    @Published var error: String?

    /// Groups counts by post name for display
    var countsByPost: [(postName: String, areaName: String?, items: [CaptainAttendanceCountItem])] {
        let grouped = Dictionary(grouping: counts) { $0.postId }
        return grouped.values
            .sorted { ($0.first?.postName ?? "").localizedStandardCompare($1.first?.postName ?? "") == .orderedAscending }
            .map { items in
                (postName: items.first?.postName ?? "",
                 areaName: items.first?.areaName,
                 items: items.sorted { $0.sessionDate < $1.sessionDate })
            }
    }

    func load(eventId: String) async {
        isLoading = true
        error = nil

        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.CaptainAreaAttendanceCountsQuery(eventId: eventId),
                cachePolicy: .fetchIgnoringCacheData
            )

            guard let data = result.data?.captainAreaAttendanceCounts else {
                error = "Failed to load attendance counts"
                isLoading = false
                return
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let fallback = ISO8601DateFormatter()

            func parseDate(_ str: String) -> Date {
                formatter.date(from: str) ?? fallback.date(from: str) ?? Date()
            }

            counts = data.map { item in
                let submitterName = [item.submittedBy.firstName, item.submittedBy.lastName]
                    .compactMap { $0 }
                    .joined(separator: " ")

                return CaptainAttendanceCountItem(
                    id: "\(item.post.id)-\(item.session.id)",
                    postId: item.post.id,
                    postName: item.post.name,
                    postLocation: item.post.location,
                    areaId: item.post.area?.id,
                    areaName: item.post.area?.name,
                    sessionId: item.session.id,
                    sessionName: item.session.name,
                    sessionDate: parseDate(item.session.date),
                    count: item.count,
                    section: item.section,
                    notes: item.notes,
                    submittedByName: submitterName,
                    submittedAt: parseDate(item.submittedAt)
                )
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
