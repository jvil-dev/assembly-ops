//
//  APITypes.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/23/25.
//

import Foundation

// MARK: - Generic API Response

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
}

// MARK: - Auth Requests

struct OverseerLoginRequest: Encodable {
    let email: String
    let password: String
}

struct OverseerRegisterRequest: Encodable {
    let email: String
    let password: String
    let name: String
}

struct VolunteerLoginRequest: Encodable {
    let odid: String
    let token: String
    let eventId: String
}

struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}

// MARK: - Auth Responses

struct OverseerAuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let overseer: OverseerDTO
    
    // Map from backend "admin" field
    enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case overseer = "admin"  // Backend uses "admin", we use "overseer"
    }
}

struct VolunteerAuthResponse: Decodable {
    let token: String
    let volunteer: VolunteerDTO
}

struct RefreshTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}

// MARK: - DTOs (Data Transfer Objects)

struct OverseerDTO: Decodable {
    let id: String
    let email: String
    let name: String
    let createdAt: String
    let updatedAt: String
}

struct VolunteerDTO: Decodable {
    let id: String
    let odid: String
    let firstName: String
    let lastName: String
    let congregation: String
    let appointment: String
    let phone: String?
    let email: String?
    let notes: String?
    let isActive: Bool
    let eventId: String
    let roleId: String?
    let createdAt: String
    let updatedAt: String
}

struct EventDTO: Decodable {
    let id: String
    let name: String
    let eventType: String
    let circuit: String?
    let date: String
    let endDate: String?
    let theme: String
    let scripture: String
    let venueName: String
    let streetAddress: String
    let city: String
    let state: String
    let zip: String
    let isActive: Bool
    let createdById: String
    let createdAt: String
    let updatedAt: String
}

struct DepartmentDTO: Decodable {
    let id: String
    let departmentType: String
    let eventId: String
    let overseerId: String?
    let overseerName: String?
    let createdAt: String
    let updatedAt: String
}

struct SessionDTO: Decodable {
    let id: String
    let name: String
    let date: String
    let startTime: String
    let endTime: String
    let displayOrder: Int
    let eventId: String
    let createdAt: String
    let updatedAt: String
}

struct AssignmentDTO: Decodable {
    let id: String
    let name: String
    let capacity: Int
    let description: String?
    let displayOrder: Int
    let eventId: String
    let departmentId: String?
    let createdAt: String
    let updatedAt: String
}

struct RoleDTO: Decodable {
    let id: String
    let name: String
    let displayOrder: Int
    let eventId: String
    let createdAt: String
    let updatedAt: String
}

struct CheckInDTO: Decodable {
    let id: String
    let status: String
    let checkInTime: String?
    let checkOutTime: String?
    let notes: String?
    let volunteerId: String
    let sessionId: String
    let createdAt: String
    let updatedAt: String
}

struct MessageDTO: Decodable {
    let id: String
    let content: String
    let priority: String
    let recipientType: String
    let targetAssignmentId: String?
    let targetRoleId: String?
    let isQuickAlert: Bool
    let quickAlertType: String?
    let sentAt: String
    let eventId: String
    let senderId: String
    let createdAt: String
    let updatedAt: String
}

struct AttendanceCountDTO: Decodable {
    let id: String
    let count: Int
    let countTime: String
    let notes: String?
    let sessionId: String
    let assignmentId: String?
    let submittedById: String
    let submittedAt: String
    let createdAt: String
    let updatedAt: String
}

// MARK: - Create/Update Requests

struct CreateEventRequest: Encodable {
    let name: String
    let eventType: String
    let circuit: String?
    let date: String
    let endDate: String?
    let theme: String
    let scripture: String
    let venueName: String
    let streetAddress: String
    let city: String
    let state: String
    let zip: String
}

struct CreateVolunteerRequest: Encodable {
    let firstName: String
    let lastName: String
    let congregation: String
    let appointment: String
    let phone: String?
    let email: String?
    let notes: String?
    let roleId: String?
    let departmentId: String?
}

struct CreateAssignmentRequest: Encodable {
    let name: String
    let capacity: Int
    let description: String?
    let displayOrder: Int?
    let departmentId: String?
}

struct CreateSessionRequest: Encodable {
    let name: String
    let date: String
    let startTime: String
    let endTime: String
    let displayOrder: Int?
}

struct CreateCheckInRequest: Encodable {
    let volunteerId: String
    let sessionId: String
    let status: String?
}

struct UpdateCheckInRequest: Encodable {
    let status: String?
    let checkOutTime: String?
    let notes: String?
}

struct CreateMessageRequest: Encodable {
    let content: String
    let priority: String?
    let recipientType: String
    let targetAssignmentId: String?
    let targetRoleId: String?
    let volunteerIds: [String]?
    let isQuickAlert: Bool?
    let quickAlertType: String?
}

struct CreateAttendanceCountRequest: Encodable {
    let count: Int
    let countTime: String?
    let notes: String?
    let sessionId: String
    let assignmentId: String?
}

// MARK: - Pagination

struct PaginatedResponse<T: Decodable>: Decodable {
    let data: [T]
    let pagination: PaginationInfo
}

struct PaginationInfo: Decodable {
    let total: Int
    let page: Int
    let limit: Int
    let totalPages: Int
}

// MARK: - Sync

struct SyncResponse: Decodable {
    let events: [EventDTO]?
    let volunteers: [VolunteerDTO]?
    let sessions: [SessionDTO]?
    let assignments: [AssignmentDTO]?
    let roles: [RoleDTO]?
    let checkIns: [CheckInDTO]?
    let messages: [MessageDTO]?
    let lastSyncTimestamp: String
}

struct DeltaSyncRequest: Encodable {
    let lastSyncTimestamp: String
    let eventId: String
}
