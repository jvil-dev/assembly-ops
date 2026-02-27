//
//  AreaModels.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

// MARK: - Area Models
//
// Data models for area-based captain group management.
// Used by AreaService and AreaManagementViewModel.
//
// Types:
//   - AreaItem: Area with posts and captain assignments
//   - AreaPostItem: Lightweight post within an area
//   - AreaCaptainItem: Captain assignment for an area+session
//   - AreaGroupItem: Captain's group view (area + captain + members)
//   - AreaGroupMemberItem: Individual member within an area group
//
// Data Flow:
//   1. GraphQL queries return Apollo generated types
//   2. init(from:) mappers convert to these domain models
//   3. ViewModels expose these types to Views
//

import Foundation

// MARK: - Area

struct AreaItem: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let category: String?
    let sortOrder: Int
    let postCount: Int
    var posts: [AreaPostItem]
    var captains: [AreaCaptainItem]
}

extension AreaItem {
    init(from data: AssemblyOpsAPI.DepartmentAreasQuery.Data.DepartmentArea) {
        self.id = data.id
        self.name = data.name
        self.description = data.description
        self.category = data.category
        self.sortOrder = data.sortOrder
        self.postCount = data.postCount
        self.posts = data.posts.map { AreaPostItem(from: $0) }
        self.captains = data.captains.map { AreaCaptainItem(from: $0) }
    }

    init(fromCreate data: AssemblyOpsAPI.CreateAreaMutation.Data.CreateArea) {
        self.id = data.id
        self.name = data.name
        self.description = data.description
        self.category = data.category
        self.sortOrder = data.sortOrder
        self.postCount = data.postCount
        self.posts = []
        self.captains = []
    }

    init(fromUpdate data: AssemblyOpsAPI.UpdateAreaMutation.Data.UpdateArea) {
        self.id = data.id
        self.name = data.name
        self.description = data.description
        self.category = data.category
        self.sortOrder = data.sortOrder
        self.postCount = data.postCount
        self.posts = []
        self.captains = []
    }
}

// MARK: - Area Post (lightweight)

struct AreaPostItem: Identifiable, Equatable {
    let id: String
    let name: String
    let capacity: Int
    let category: String?
    let sortOrder: Int
}

extension AreaPostItem {
    init(from data: AssemblyOpsAPI.DepartmentAreasQuery.Data.DepartmentArea.Post) {
        self.id = data.id
        self.name = data.name
        self.capacity = data.capacity
        self.category = data.category
        self.sortOrder = data.sortOrder
    }
}

// MARK: - Area Captain Assignment

struct AreaCaptainItem: Identifiable, Equatable {
    let id: String
    let sessionId: String
    let sessionName: String
    let sessionDate: Date?
    let eventVolunteerId: String
    let volunteerId: String
    let volunteerName: String
}

extension AreaCaptainItem {
    init(from data: AssemblyOpsAPI.DepartmentAreasQuery.Data.DepartmentArea.Captain) {
        self.id = data.id
        self.sessionId = data.session.id
        self.sessionName = data.session.name
        self.sessionDate = DateUtils.parseISO8601(data.session.date)
        self.eventVolunteerId = data.eventVolunteer.id
        self.volunteerId = data.eventVolunteer.volunteerId
        let user = data.eventVolunteer.user
        self.volunteerName = "\(user.firstName) \(user.lastName)"
    }

    init(fromSet data: AssemblyOpsAPI.SetAreaCaptainMutation.Data.SetAreaCaptain) {
        self.id = data.id
        self.sessionId = data.session.id
        self.sessionName = data.session.name
        self.sessionDate = nil
        self.eventVolunteerId = data.eventVolunteer.id
        self.volunteerId = data.eventVolunteer.volunteerId
        let user = data.eventVolunteer.user
        self.volunteerName = "\(user.firstName) \(user.lastName)"
    }
}

// MARK: - Area Group (captain's view)

struct AreaGroupItem: Identifiable {
    var id: String { "\(areaId)-\(sessionId ?? "unknown")" }
    let areaId: String
    let areaName: String
    let areaDescription: String?
    let areaCategory: String?
    let sessionId: String?
    let sessionName: String?
    let sessionDate: Date?
    let sessionStartTime: Date?
    let sessionEndTime: Date?
    let captainId: String?
    let captainName: String?
    let captainEventVolunteerId: String?
    var members: [AreaGroupMemberItem]
}

extension AreaGroupItem {
    init(from data: AssemblyOpsAPI.AreaGroupQuery.Data.AreaGroup) {
        self.areaId = data.area.id
        self.areaName = data.area.name
        self.areaDescription = data.area.description
        self.areaCategory = data.area.category
        self.sessionId = data.captain?.session.id
        self.sessionName = data.captain?.session.name
        self.sessionDate = nil
        self.sessionStartTime = nil
        self.sessionEndTime = nil
        if let captain = data.captain {
            self.captainId = captain.id
            let user = captain.eventVolunteer.user
            self.captainName = "\(user.firstName) \(user.lastName)"
            self.captainEventVolunteerId = captain.eventVolunteer.id
        } else {
            self.captainId = nil
            self.captainName = nil
            self.captainEventVolunteerId = nil
        }
        self.members = data.members.map { AreaGroupMemberItem(from: $0) }
    }

    init(fromMyGroup data: AssemblyOpsAPI.MyAreaGroupsQuery.Data.MyAreaGroup) {
        self.areaId = data.area.id
        self.areaName = data.area.name
        self.areaDescription = data.area.description
        self.areaCategory = data.area.category
        if let captain = data.captain {
            self.sessionId = captain.session.id
            self.sessionName = captain.session.name
            self.sessionDate = DateUtils.parseISO8601(captain.session.date)
            self.sessionStartTime = DateUtils.parseISO8601(captain.session.startTime)
            self.sessionEndTime = DateUtils.parseISO8601(captain.session.endTime)
            self.captainId = captain.id
            let user = captain.eventVolunteer.user
            self.captainName = "\(user.firstName) \(user.lastName)"
            self.captainEventVolunteerId = captain.eventVolunteer.id
        } else {
            self.sessionId = nil
            self.sessionName = nil
            self.sessionDate = nil
            self.sessionStartTime = nil
            self.sessionEndTime = nil
            self.captainId = nil
            self.captainName = nil
            self.captainEventVolunteerId = nil
        }
        self.members = data.members.map { AreaGroupMemberItem(fromMyGroup: $0) }
    }
}

// MARK: - Area Group Member

struct AreaGroupMemberItem: Identifiable {
    var id: String { assignmentId }
    let assignmentId: String
    let postName: String
    let postId: String
    let volunteerId: String
    let volunteerName: String
    let congregation: String
    let phone: String?
    let status: String
    let isCaptain: Bool
    let checkInId: String?
    let checkInStatus: String?
    let checkInTime: Date?
}

extension AreaGroupMemberItem {
    init(from data: AssemblyOpsAPI.AreaGroupQuery.Data.AreaGroup.Member) {
        self.postName = data.postName
        self.postId = data.postId
        self.assignmentId = data.assignment.id
        self.volunteerId = data.assignment.volunteer?.id ?? ""
        self.volunteerName = "\(data.assignment.volunteer?.firstName ?? "") \(data.assignment.volunteer?.lastName ?? "")"
        self.congregation = data.assignment.volunteer?.congregation ?? ""
        self.phone = data.assignment.volunteer?.phone
        self.status = data.assignment.status.rawValue
        self.isCaptain = data.assignment.isCaptain
        self.checkInId = data.assignment.checkIn?.id
        self.checkInStatus = data.assignment.checkIn?.status.rawValue
        if let checkIn = data.assignment.checkIn {
            self.checkInTime = DateUtils.parseISO8601(checkIn.checkInTime)
        } else {
            self.checkInTime = nil
        }
    }

    init(fromMyGroup data: AssemblyOpsAPI.MyAreaGroupsQuery.Data.MyAreaGroup.Member) {
        self.postName = data.postName
        self.postId = data.postId
        self.assignmentId = data.assignment.id
        self.volunteerId = data.assignment.volunteer?.id ?? ""
        self.volunteerName = "\(data.assignment.volunteer?.firstName ?? "") \(data.assignment.volunteer?.lastName ?? "")"
        self.congregation = data.assignment.volunteer?.congregation ?? ""
        self.phone = data.assignment.volunteer?.phone
        self.status = data.assignment.status.rawValue
        self.isCaptain = false
        self.checkInId = data.assignment.checkIn?.id
        self.checkInStatus = data.assignment.checkIn?.status.rawValue
        if let checkIn = data.assignment.checkIn {
            self.checkInTime = DateUtils.parseISO8601(checkIn.checkInTime)
        } else {
            self.checkInTime = nil
        }
    }
}
