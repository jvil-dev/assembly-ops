//
//  VolunteerEventDiscoveryViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/24/26.
//

// MARK: - Volunteer Event Discovery View Model
//
// Loads publicly visible events and handles join requests.
// Used by VolunteerEventDiscoveryView.
//
// Methods:
//   - loadEvents(): Fetch public events from discoverEvents query
//   - requestToJoin(eventId:departmentType:note:): Submit join request
//

import Foundation
import Combine
import Apollo

struct DiscoverableEvent: Identifiable {
    let id: String
    let name: String
    let eventType: String      // raw value e.g. "CIRCUIT_ASSEMBLY"
    let venue: String
    let address: String
    let startDate: String
    let endDate: String
    let isPublic: Bool
    let volunteerCount: Int

    var isInviteOnly: Bool {
        eventType == "REGIONAL_CONVENTION" || eventType == "SPECIAL_CONVENTION"
    }

    var displayEventType: String {
        switch eventType {
        case "CIRCUIT_ASSEMBLY": return "Circuit Assembly"
        case "REGIONAL_CONVENTION": return "Regional Convention"
        case "SPECIAL_CONVENTION": return "Special Convention"
        default: return eventType
        }
    }
}

@MainActor
final class VolunteerEventDiscoveryViewModel: ObservableObject {
    @Published var events: [DiscoverableEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Tracks pending requests by eventId
    @Published var pendingRequestIds: Set<String> = []
    @Published var sentRequestIds: Set<String> = []

    func loadEvents() {
        isLoading = true
        errorMessage = nil

        NetworkClient.shared.apollo.fetch(
            query: AssemblyOpsAPI.DiscoverEventsQuery(eventType: .none),
            cachePolicy: .fetchIgnoringCacheData
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.discoverEvents {
                        self?.events = data.map { e in
                            DiscoverableEvent(
                                id: e.id,
                                name: e.name,
                                eventType: e.eventType.rawValue,
                                venue: e.venue,
                                address: e.address,
                                startDate: e.startDate,
                                endDate: e.endDate,
                                isPublic: e.isPublic,
                                volunteerCount: e.volunteerCount
                            )
                        }
                    }
                case .failure(let error):
                    self?.errorMessage = "Failed to load events: \(error.localizedDescription)"
                }
                self?.isLoading = false
            }
        }
    }

    func requestToJoin(eventId: String, departmentType: String? = nil, note: String? = nil) {
        guard !pendingRequestIds.contains(eventId) else { return }
        pendingRequestIds.insert(eventId)

        let deptEnum: GraphQLNullable<GraphQLEnum<AssemblyOpsAPI.DepartmentType>>
        if let dt = departmentType {
            deptEnum = .some(GraphQLEnum(rawValue: dt))
        } else {
            deptEnum = .none
        }

        let noteValue: GraphQLNullable<String> = note.map { .some($0) } ?? .none

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.RequestToJoinEventMutation(
                eventId: eventId,
                departmentType: deptEnum,
                note: noteValue
            )
        ) { [weak self] result in
            Task { @MainActor in
                self?.pendingRequestIds.remove(eventId)
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.requestToJoinEvent != nil {
                        self?.sentRequestIds.insert(eventId)
                        HapticManager.shared.success()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.message ?? "Request failed"
                        HapticManager.shared.error()
                    }
                case .failure:
                    self?.errorMessage = "Unable to send request. Please try again."
                    HapticManager.shared.error()
                }
            }
        }
    }
}
