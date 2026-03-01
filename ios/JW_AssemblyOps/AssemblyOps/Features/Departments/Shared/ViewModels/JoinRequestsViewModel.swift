//
//  JoinRequestsViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/24/26.
//

// MARK: - Join Requests View Model
//
// Loads and manages volunteer join requests for an overseer's event.
// Used by JoinRequestsView.
//
// Methods:
//   - loadRequests(eventId:): Fetch PENDING join requests
//   - approve(requestId:): Approve → returns EventVolunteerCredentials
//   - deny(requestId:reason:): Deny → removes from list
//

import Foundation
import Combine
import Apollo

struct JoinRequestItem: Identifiable {
    let id: String
    let eventId: String
    let userId: String
    let userFirstName: String
    let userLastName: String
    let userFullName: String
    let userCongregation: String?
    let userAppointmentStatus: String?
    let departmentType: String?
    let status: String
    let note: String?
    let createdAt: String

    var displayDepartment: String? {
        guard let dt = departmentType else { return nil }
        switch dt {
        case "ACCOUNTS": return "Accounts"
        case "ATTENDANT": return "Attendant"
        case "AUDIO": return "Audio"
        case "VIDEO": return "Video"
        case "STAGE": return "Stage"
        case "BAPTISM": return "Baptism"
        case "CLEANING": return "Cleaning"
        case "FIRST_AID": return "First Aid"
        case "INFORMATION_VOLUNTEER_SERVICE": return "Information & Volunteer Service"
        case "INSTALLATION": return "Installation"
        case "LOST_FOUND_CHECKROOM": return "Lost & Found/Checkroom"
        case "PARKING": return "Parking"
        case "ROOMING": return "Rooming"
        case "TRUCKING_EQUIPMENT": return "Trucking & Equipment"
        default: return dt
        }
    }

    var displayAppointment: String? {
        guard let status = userAppointmentStatus else { return nil }
        switch status {
        case "PUBLISHER": return "Publisher"
        case "MINISTERIAL_SERVANT": return "Ministerial Servant"
        case "ELDER": return "Elder"
        default: return status
        }
    }
}

struct ApprovedResult: Equatable {
    let requestId: String
    let userFullName: String
}

@MainActor
final class JoinRequestsViewModel: ObservableObject {
    @Published var requests: [JoinRequestItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var approvedResult: ApprovedResult?
    @Published var processingIds: Set<String> = []

    func loadRequests(eventId: String) {
        isLoading = true
        errorMessage = nil

        NetworkClient.shared.apollo.fetch(
            query: AssemblyOpsAPI.EventJoinRequestsQuery(
                eventId: eventId,
                status: .some(.case(.pending))
            ),
            cachePolicy: .fetchIgnoringCacheData
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.eventJoinRequests {
                        self?.requests = data.map { r in
                            JoinRequestItem(
                                id: r.id,
                                eventId: r.eventId,
                                userId: r.user.userId,
                                userFirstName: r.user.firstName,
                                userLastName: r.user.lastName,
                                userFullName: r.user.firstName + " " + r.user.lastName,
                                userCongregation: r.user.congregation,
                                userAppointmentStatus: r.user.appointmentStatus?.rawValue,
                                departmentType: r.departmentType?.rawValue,
                                status: r.status.rawValue,
                                note: r.note,
                                createdAt: r.createdAt
                            )
                        }
                    }
                case .failure(let error):
                    self?.errorMessage = "Failed to load requests: \(error.localizedDescription)"
                }
                self?.isLoading = false
            }
        }
    }

    func approve(requestId: String) {
        guard !processingIds.contains(requestId) else { return }
        processingIds.insert(requestId)

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.ApproveJoinRequestMutation(requestId: requestId)
        ) { [weak self] result in
            Task { @MainActor in
                self?.processingIds.remove(requestId)
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.approveJoinRequest != nil {
                        let requestItem = self?.requests.first(where: { $0.id == requestId })
                        self?.approvedResult = ApprovedResult(
                            requestId: requestId,
                            userFullName: requestItem?.userFullName ?? "Volunteer"
                        )
                        self?.requests.removeAll(where: { $0.id == requestId })
                        HapticManager.shared.success()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.message ?? "Approval failed"
                        HapticManager.shared.error()
                    }
                case .failure:
                    self?.errorMessage = "Unable to approve. Please try again."
                    HapticManager.shared.error()
                }
            }
        }
    }

    func deny(requestId: String, reason: String? = nil) {
        guard !processingIds.contains(requestId) else { return }
        processingIds.insert(requestId)

        let reasonValue: GraphQLNullable<String> = reason.map { .some($0) } ?? .none

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.DenyJoinRequestMutation(requestId: requestId, reason: reasonValue)
        ) { [weak self] result in
            Task { @MainActor in
                self?.processingIds.remove(requestId)
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.message ?? "Denial failed"
                        HapticManager.shared.error()
                    } else if graphQLResult.data != nil {
                        self?.requests.removeAll(where: { $0.id == requestId })
                        HapticManager.shared.lightTap()
                    }
                case .failure:
                    self?.errorMessage = "Unable to deny. Please try again."
                    HapticManager.shared.error()
                }
            }
        }
    }
}
