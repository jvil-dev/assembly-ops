//
//  ArchivedEventsViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/25/26.
//

// MARK: - Archived Events ViewModel
//
// Loads all user events via MyAllEventsQuery and filters to archived items.
// Archived = past event && ended more than 30 days ago.

import Foundation
import Combine
import Apollo

@MainActor
final class ArchivedEventsViewModel: ObservableObject {
    @Published var archivedEvents: [ArchivedEventItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    struct ArchivedEventItem: Identifiable {
        let id: String
        let eventName: String
        let eventType: String
        let role: String
        let departmentName: String?
        let venue: String
        let startDate: Date
        let endDate: Date

        var dateRangeString: String {
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM d, yyyy"
            return "\(fmt.string(from: startDate)) – \(fmt.string(from: endDate))"
        }

        var displayEventType: String {
            switch eventType {
            case "CIRCUIT_ASSEMBLY": return "Circuit Assembly"
            case "REGIONAL_CONVENTION": return "Regional Convention"
            case "SPECIAL_CONVENTION": return "Special Convention"
            default: return eventType
            }
        }

        var displayRole: String {
            if role == "DEPARTMENT_OVERSEER" {
                if let dept = departmentName {
                    return String(format: "eventsHub.role.deptOverseer".localized, dept)
                }
                return "eventsHub.role.overseer".localized
            }
            return "eventsHub.role.volunteer".localized
        }
    }

    func reload() async {
        await withCheckedContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.MyAllEventsQuery(),
                cachePolicy: .fetchIgnoringCacheData
            ) { [weak self] result in
                Task { @MainActor in
                    switch result {
                    case .success(let graphQLResult):
                        if let events = graphQLResult.data?.myAllEvents {
                            let now = Date()
                            let archiveThreshold = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
                            self?.archivedEvents = events.compactMap { e in
                                guard let endDate = DateUtils.parseISO8601(e.event.endDate),
                                      let startDate = DateUtils.parseISO8601(e.event.startDate),
                                      endDate < archiveThreshold else { return nil }
                                return ArchivedEventItem(
                                    id: e.eventId,
                                    eventName: e.event.name,
                                    eventType: e.event.eventType.rawValue,
                                    role: e.overseerRole?.rawValue ?? "VOLUNTEER",
                                    departmentName: e.departmentName,
                                    venue: e.event.venue,
                                    startDate: startDate,
                                    endDate: endDate
                                )
                            }
                            .sorted { $0.endDate > $1.endDate }
                        }
                    case .failure(let error):
                        self?.errorMessage = error.localizedDescription
                    }
                    continuation.resume()
                }
            }
        }
    }

    func loadArchivedEvents() {
        isLoading = true
        errorMessage = nil

        NetworkClient.shared.apollo.fetch(
            query: AssemblyOpsAPI.MyAllEventsQuery(),
            cachePolicy: .fetchIgnoringCacheData
        ) { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                switch result {
                case .success(let graphQLResult):
                    if let events = graphQLResult.data?.myAllEvents {
                        let now = Date()
                        let archiveThreshold = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now

                        self?.archivedEvents = events.compactMap { e in
                            guard let endDate = DateUtils.parseISO8601(e.event.endDate),
                                  let startDate = DateUtils.parseISO8601(e.event.startDate),
                                  endDate < archiveThreshold else {
                                return nil
                            }

                            return ArchivedEventItem(
                                id: e.eventId,
                                eventName: e.event.name,
                                eventType: e.event.eventType.rawValue,
                                role: e.overseerRole?.rawValue ?? "VOLUNTEER",
                                departmentName: e.departmentName,
                                venue: e.event.venue,
                                startDate: startDate,
                                endDate: endDate
                            )
                        }
                        .sorted { $0.endDate > $1.endDate }
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
