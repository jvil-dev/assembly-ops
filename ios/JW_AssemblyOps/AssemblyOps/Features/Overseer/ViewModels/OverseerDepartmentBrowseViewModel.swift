//
//  OverseerDepartmentBrowseViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/26/26.
//

import Foundation
import Combine
import Apollo

@MainActor
final class OverseerDepartmentBrowseViewModel: ObservableObject {
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
