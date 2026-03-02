//
//  DepartmentBrowseViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/26/26.
//

import Foundation
import Combine
import Apollo

@MainActor
final class DepartmentBrowseViewModel: ObservableObject {
    @Published var events: [DiscoverableEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Purchase state
    @Published var isPurchasing = false
    @Published var purchasedDepartment: PurchasedDepartmentResult?

    struct PurchasedDepartmentResult: Identifiable, Hashable {
        let id: String
        let name: String
        let departmentType: String
        let accessCode: String
    }

    // MARK: - Sectioned Event Lists

    @Published var conventionSearchText = ""

    var circuitAssemblies: [DiscoverableEvent] {
        events.filter { $0.eventType.hasPrefix("CIRCUIT_ASSEMBLY") }
    }

    var conventions: [DiscoverableEvent] {
        events.filter { $0.eventType == "REGIONAL_CONVENTION" || $0.eventType == "SPECIAL_CONVENTION" }
    }

    var filteredConventions: [DiscoverableEvent] {
        guard !conventionSearchText.isEmpty else { return conventions }
        let query = conventionSearchText.lowercased()
        return conventions.filter {
            $0.venue.lowercased().contains(query) ||
            $0.address.lowercased().contains(query) ||
            ($0.state?.lowercased().contains(query) ?? false) ||
            $0.name.lowercased().contains(query) ||
            Self.formattedDateRange($0.startDate, $0.endDate).lowercased().contains(query)
        }
    }

    private static func formattedDateRange(_ start: String, _ end: String) -> String {
        DateUtils.formatEventFullDateRange(from: start, to: end)
    }

    // MARK: - Network

    func loadEvents() {
        isLoading = true
        errorMessage = nil

        let circuitCodeFilter: GraphQLNullable<String> = AppState.shared.currentUser?.circuitCode.map { .some($0) } ?? .none

        NetworkClient.shared.apollo.fetch(
            query: AssemblyOpsAPI.DiscoverEventsQuery(
                eventType: .none,
                state: .none,
                language: .none,
                circuitCode: circuitCodeFilter
            ),
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
                                circuit: e.circuit,
                                state: e.state,
                                venue: e.venue,
                                address: e.address,
                                startDate: e.startDate,
                                endDate: e.endDate,
                                theme: e.theme,
                                isPublic: e.isPublic,
                                volunteerCount: e.volunteerCount,
                                departments: e.departments.map { d in
                                    EventDepartmentInfo(
                                        id: d.id,
                                        name: d.name,
                                        departmentType: d.departmentType.rawValue,
                                        volunteerCount: d.volunteerCount
                                    )
                                }
                            )
                        }
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
                self?.isLoading = false
            }
        }
    }

    func purchaseDepartment(eventId: String, departmentType: String) {
        isPurchasing = true
        errorMessage = nil

        let deptEnum = GraphQLEnum<AssemblyOpsAPI.DepartmentType>(rawValue: departmentType)
        let input = AssemblyOpsAPI.PurchaseDepartmentInput(eventId: eventId, departmentType: deptEnum)

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.PurchaseDepartmentMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                self?.isPurchasing = false
                switch result {
                case .success(let graphQLResult):
                    if let dept = graphQLResult.data?.purchaseDepartment {
                        self?.purchasedDepartment = PurchasedDepartmentResult(
                            id: dept.id,
                            name: dept.name,
                            departmentType: dept.departmentType.rawValue,
                            accessCode: dept.accessCode ?? ""
                        )
                        HapticManager.shared.success()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.message ?? "Purchase failed"
                        HapticManager.shared.error()
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    HapticManager.shared.error()
                }
            }
        }
    }
}
