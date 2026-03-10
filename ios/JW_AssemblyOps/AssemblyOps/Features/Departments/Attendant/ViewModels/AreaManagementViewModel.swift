//
//  AreaManagementViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

// MARK: - Area Management View Model
//
// Manages area CRUD and captain management for the Overseer area management UI.
//
// Properties:
//   - areas: All areas in the current department
//   - isLoading: Loading state
//   - error: Error message
//
// Methods:
//   - loadAreas(departmentId:): Fetch all areas for a department
//   - createArea(departmentId:name:description:category:sortOrder:): Create a new area
//   - updateArea(id:name:description:sortOrder:): Update an area
//   - deleteArea(id:): Delete an area
//   - setAreaCaptain(areaId:sessionId:eventVolunteerId:): Assign a captain
//   - removeAreaCaptain(areaId:sessionId:): Remove a captain
//   - loadAreaGroup(areaId:sessionId:): Fetch area group details
//

import Foundation
import Combine

@MainActor
final class AreaManagementViewModel: ObservableObject {
    @Published var areas: [AreaItem] = []
    @Published var currentGroup: AreaGroupItem?
    @Published var isLoading = false
    @Published var error: String?

    private let areaService = AreaService.shared

    // MARK: - Area CRUD

    /// Load all areas for a department
    func loadAreas(departmentId: String) async {
        isLoading = true
        error = nil

        do {
            areas = try await areaService.fetchDepartmentAreas(departmentId: departmentId)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    /// Create a new area
    func createArea(departmentId: String, name: String, description: String?, category: String?, sortOrder: Int?, startTime: String? = nil, endTime: String? = nil) async {
        isLoading = true
        error = nil

        do {
            let newArea = try await areaService.createArea(
                departmentId: departmentId,
                name: name,
                description: description,
                category: category,
                sortOrder: sortOrder,
                startTime: startTime,
                endTime: endTime
            )
            areas.append(newArea)
            areas.sort { $0.sortOrder < $1.sortOrder }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    /// Update an existing area
    func updateArea(id: String, name: String, description: String?, sortOrder: Int?, startTime: String? = nil, endTime: String? = nil) async {
        error = nil

        do {
            let updated = try await areaService.updateArea(
                id: id,
                name: name,
                description: description,
                sortOrder: sortOrder,
                startTime: startTime,
                endTime: endTime
            )
            if let index = areas.firstIndex(where: { $0.id == id }) {
                // Preserve existing posts and captains since mutation returns without them
                var merged = updated
                merged.posts = areas[index].posts
                merged.captains = areas[index].captains
                areas[index] = merged
                areas.sort { $0.sortOrder < $1.sortOrder }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Delete an area
    func deleteArea(id: String) async {
        error = nil

        do {
            try await areaService.deleteArea(id: id)
            areas.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Captain Management

    /// Set captain for an area + session
    func setAreaCaptain(areaId: String, sessionId: String, eventVolunteerId: String, forceAssigned: Bool = false, acceptedDeadline: Date? = nil) async {
        error = nil

        do {
            let captain = try await areaService.setAreaCaptain(
                areaId: areaId,
                sessionId: sessionId,
                eventVolunteerId: eventVolunteerId,
                forceAssigned: forceAssigned,
                acceptedDeadline: acceptedDeadline
            )
            // Update local captain list for this area
            if let areaIndex = areas.firstIndex(where: { $0.id == areaId }) {
                // Remove existing captain for this session, then add new one
                areas[areaIndex].captains.removeAll { $0.sessionId == sessionId }
                areas[areaIndex].captains.append(captain)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Remove captain from an area + session
    func removeAreaCaptain(areaId: String, sessionId: String) async {
        error = nil

        do {
            try await areaService.removeAreaCaptain(areaId: areaId, sessionId: sessionId)
            // Update local captain list
            if let areaIndex = areas.firstIndex(where: { $0.id == areaId }) {
                areas[areaIndex].captains.removeAll { $0.sessionId == sessionId }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Area Group

    /// Load area group details (captain + members)
    func loadAreaGroup(areaId: String, sessionId: String) async {
        isLoading = true
        error = nil

        do {
            currentGroup = try await areaService.fetchAreaGroup(areaId: areaId, sessionId: sessionId)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
