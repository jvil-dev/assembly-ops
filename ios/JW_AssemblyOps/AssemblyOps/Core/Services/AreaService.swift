//
//  AreaService.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

// MARK: - Area Service
//
// Handles all area management GraphQL API calls.
// Manages areas, area captain assignments, and area groups.
//
// Methods:
//   - fetchDepartmentAreas(departmentId:): Get all areas for a department
//   - createArea(departmentId:name:description:category:sortOrder:): Create a new area
//   - updateArea(id:name:description:sortOrder:): Update an area
//   - deleteArea(id:): Delete an area
//   - setAreaCaptain(areaId:sessionId:eventVolunteerId:): Set captain for area+session
//   - removeAreaCaptain(areaId:sessionId:): Remove captain from area+session
//   - fetchAreaGroup(areaId:sessionId:): Get area group (captain + members)
//   - fetchMyAreaGroups(): Get all area groups where current user is captain
//
// Dependencies:
//   - NetworkClient: Apollo client for GraphQL

import Foundation
import Apollo

enum AreaError: LocalizedError {
    case networkError(String)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let message): return "Network error: \(message)"
        case .serverError(let message): return message
        }
    }
}

/// Service for area management operations
final class AreaService {
    static let shared = AreaService()

    private init() {}

    // MARK: - Area CRUD

    /// Fetch all areas for a department
    func fetchDepartmentAreas(departmentId: String) async throws -> [AreaItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.DepartmentAreasQuery(departmentId: departmentId),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.departmentAreas {
                        let areas = data.map { AreaItem(from: $0) }
                        continuation.resume(returning: areas)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AreaError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AreaError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Create a new area
    func createArea(departmentId: String, name: String, description: String?, category: String?, sortOrder: Int?) async throws -> AreaItem {
        let input = AssemblyOpsAPI.CreateAreaInput(
            name: name,
            description: description.map { .some($0) } ?? .none,
            category: category.map { .some($0) } ?? .none,
            sortOrder: sortOrder.map { .some($0) } ?? .none
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.CreateAreaMutation(departmentId: departmentId, input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.createArea {
                        let area = AreaItem(fromCreate: data)
                        continuation.resume(returning: area)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AreaError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AreaError.serverError("Failed to create area"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AreaError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Update an existing area
    func updateArea(id: String, name: String?, description: String?, sortOrder: Int?) async throws -> AreaItem {
        let input = AssemblyOpsAPI.UpdateAreaInput(
            name: name.map { .some($0) } ?? .none,
            description: description.map { .some($0) } ?? .none,
            sortOrder: sortOrder.map { .some($0) } ?? .none
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.UpdateAreaMutation(id: id, input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.updateArea {
                        let area = AreaItem(fromUpdate: data)
                        continuation.resume(returning: area)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AreaError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AreaError.serverError("Failed to update area"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AreaError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Delete an area
    func deleteArea(id: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.DeleteAreaMutation(id: id)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.deleteArea != nil {
                        continuation.resume()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AreaError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AreaError.serverError("Failed to delete area"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AreaError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Captain Management

    /// Set captain for an area + session
    func setAreaCaptain(areaId: String, sessionId: String, eventVolunteerId: String) async throws -> AreaCaptainItem {
        let input = AssemblyOpsAPI.SetAreaCaptainInput(
            areaId: areaId,
            sessionId: sessionId,
            eventVolunteerId: eventVolunteerId
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.SetAreaCaptainMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.setAreaCaptain {
                        let captain = AreaCaptainItem(fromSet: data)
                        continuation.resume(returning: captain)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AreaError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AreaError.serverError("Failed to set area captain"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AreaError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Remove captain from an area + session
    func removeAreaCaptain(areaId: String, sessionId: String) async throws {
        let input = AssemblyOpsAPI.RemoveAreaCaptainInput(
            areaId: areaId,
            sessionId: sessionId
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.RemoveAreaCaptainMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.removeAreaCaptain != nil {
                        continuation.resume()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AreaError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AreaError.serverError("Failed to remove area captain"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AreaError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Area Groups

    /// Fetch area group (captain + members) for a specific area and session
    func fetchAreaGroup(areaId: String, sessionId: String) async throws -> AreaGroupItem? {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.AreaGroupQuery(areaId: areaId, sessionId: sessionId),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.areaGroup {
                        let group = AreaGroupItem(from: data)
                        continuation.resume(returning: group)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AreaError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: nil)
                    }
                case .failure(let error):
                    continuation.resume(throwing: AreaError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Fetch all area groups where the current volunteer is captain
    func fetchMyAreaGroups() async throws -> [AreaGroupItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.MyAreaGroupsQuery(),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.myAreaGroups {
                        let groups = data.map { AreaGroupItem(fromMyGroup: $0) }
                        continuation.resume(returning: groups)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AreaError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AreaError.networkError(error.localizedDescription))
                }
            }
        }
    }
}
