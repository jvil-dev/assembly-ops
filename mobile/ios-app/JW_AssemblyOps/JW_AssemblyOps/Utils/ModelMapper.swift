//
//  ModelMapper.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/23/25.
//

import Foundation

/// Converts between API DTOs and SwiftData models
enum ModelMapper {
    
    // MARK: - Overseer
    
    /// Convert OverseerDTO from API to local Overseer model
    static func toModel(_ dto: OverseerDTO) -> Overseer {
        Overseer(
            id: dto.id,
            email: dto.email,
            name: dto.name,
            overseerType: .departmentOverseer,
            createdAt: dto.createdAt.iso8601Date ?? Date(),
            updatedAt: dto.updatedAt.iso8601Date ?? Date()
        )
    }
    
    // MARK: - Event
    
    /// Convert EventDTO from API to local Event model
    static func toModel(_ dto: EventDTO) -> Event {
        Event(
            id: dto.id,
            name: dto.name,
            eventType: EventType(rawValue: dto.eventType) ?? .circuitAssembly,
            circuit: dto.circuit,
            date: dto.date.apiDate ?? Date(),
            endDate: dto.endDate?.apiDate,
            theme: dto.theme,
            scripture: dto.scripture,
            venueName: dto.venueName,
            streetAddress: dto.streetAddress,
            city: dto.city,
            state: dto.state,
            zip: dto.zip,
            isActive: dto.isActive,
            createdAt: dto.createdAt.iso8601Date ?? Date(),
            updatedAt: dto.updatedAt.iso8601Date ?? Date()
        )
    }
    
    /// Convert local Event model to API request
    static func toRequest(_ event: Event) -> CreateEventRequest {
        CreateEventRequest(
            name: event.name,
            eventType: event.eventType.rawValue,
            circuit: event.circuit,
            date: event.date.apiDateString,
            endDate: event.endDate?.apiDateString,
            theme: event.theme,
            scripture: event.scripture,
            venueName: event.venueName,
            streetAddress: event.streetAddress,
            city: event.city,
            state: event.state,
            zip: event.zip
        )
    }
    
    // MARK: - Volunteer
    
    /// Convert VolunteerDTO from API to local Volunteer model
    static func toModel(_ dto: VolunteerDTO) -> Volunteer {
        Volunteer(
            id: dto.id,
            odid: dto.odid,
            token: "",  // Token not returned from server for security
            firstName: dto.firstName,
            lastName: dto.lastName,
            congregation: dto.congregation,
            appointment: Appointment(rawValue: dto.appointment) ?? .publisher,
            phone: dto.phone,
            email: dto.email,
            notes: dto.notes,
            isActive: dto.isActive,
            createdAt: dto.createdAt.iso8601Date ?? Date(),
            updatedAt: dto.updatedAt.iso8601Date ?? Date()
        )
    }
    
    /// Convert local Volunteer model to API request
    static func toRequest(_ volunteer: Volunteer) -> CreateVolunteerRequest {
        CreateVolunteerRequest(
            firstName: volunteer.firstName,
            lastName: volunteer.lastName,
            congregation: volunteer.congregation,
            appointment: volunteer.appointment.rawValue,
            phone: volunteer.phone,
            email: volunteer.email,
            notes: volunteer.notes,
            roleId: volunteer.role?.id,
            departmentId: volunteer.department?.id
        )
    }
    
    // MARK: - Session
    
    /// Convert SessionDTO from API to local Session model
    static func toModel(_ dto: SessionDTO) -> Session {
        Session(
            id: dto.id,
            name: dto.name,
            date: dto.date.apiDate ?? Date(),
            startTime: dto.startTime.iso8601Date ?? Date(),
            endTime: dto.endTime.iso8601Date ?? Date(),
            displayOrder: dto.displayOrder,
            createdAt: dto.createdAt.iso8601Date ?? Date(),
            updatedAt: dto.updatedAt.iso8601Date ?? Date()
        )
    }
    
    /// Convert local Session model to API request
    static func toRequest(_ session: Session) -> CreateSessionRequest {
        CreateSessionRequest(
            name: session.name,
            date: session.date.apiDateString,
            startTime: session.startTime.iso8601String,
            endTime: session.endTime.iso8601String,
            displayOrder: session.displayOrder
        )
    }
    
    // MARK: - Assignment
    
    /// Convert AssignmentDTO from API to local Assignment model
    static func toModel(_ dto: AssignmentDTO) -> Assignment {
        Assignment(
            id: dto.id,
            name: dto.name,
            capacity: dto.capacity,
            description_: dto.description,
            displayOrder: dto.displayOrder,
            createdAt: dto.createdAt.iso8601Date ?? Date(),
            updatedAt: dto.updatedAt.iso8601Date ?? Date()
        )
    }
    
    /// Convert local Assignment model to API request
    static func toRequest(_ assignment: Assignment) -> CreateAssignmentRequest {
        CreateAssignmentRequest(
            name: assignment.name,
            capacity: assignment.capacity,
            description: assignment.description_,
            displayOrder: assignment.displayOrder,
            departmentId: assignment.department?.id
        )
    }
    
    // MARK: - Role
    
    /// Convert RoleDTO from API to local Role model
    static func toModel(_ dto: RoleDTO) -> Role {
        Role(
            id: dto.id,
            name: dto.name,
            displayOrder: dto.displayOrder,
            createdAt: dto.createdAt.iso8601Date ?? Date(),
            updatedAt: dto.updatedAt.iso8601Date ?? Date()
        )
    }
    
    // MARK: - Department
    
    /// Convert DepartmentDTO from API to local Department model
    static func toModel(_ dto: DepartmentDTO) -> Department {
        Department(
            id: dto.id,
            departmentType: DepartmentType(rawValue: dto.departmentType) ?? .attendant,
            overseerId: dto.overseerId,
            overseerName: dto.overseerName,
            createdAt: dto.createdAt.iso8601Date ?? Date(),
            updatedAt: dto.updatedAt.iso8601Date ?? Date()
        )
    }
    
    // MARK: - CheckIn
    
    /// Convert CheckInDTO from API to local CheckIn model
    static func toModel(_ dto: CheckInDTO) -> CheckIn {
        CheckIn(
            id: dto.id,
            status: CheckInStatus(rawValue: dto.status) ?? .checkedIn,
            checkInTime: dto.checkInTime?.iso8601Date,
            checkOutTime: dto.checkOutTime?.iso8601Date,
            notes: dto.notes,
            createdAt: dto.createdAt.iso8601Date ?? Date(),
            updatedAt: dto.updatedAt.iso8601Date ?? Date()
        )
    }
    
    /// Convert local CheckIn to API request
    static func toRequest(_ checkIn: CheckIn) -> CreateCheckInRequest {
        CreateCheckInRequest(
            volunteerId: checkIn.volunteer?.id ?? "",
            sessionId: checkIn.session?.id ?? "",
            status: checkIn.status.rawValue
        )
    }
    
    // MARK: - Message
    
    /// Convert MessageDTO from API to local Message model
    static func toModel(_ dto: MessageDTO) -> Message {
        Message(
            id: dto.id,
            content: dto.content,
            priority: MessagePriority(rawValue: dto.priority) ?? .normal,
            recipientType: RecipientType(rawValue: dto.recipientType) ?? .all,
            targetAssignmentId: dto.targetAssignmentId,
            targetRoleId: dto.targetRoleId,
            isQuickAlert: dto.isQuickAlert,
            quickAlertType: dto.quickAlertType,
            sentAt: dto.sentAt.iso8601Date ?? Date(),
            createdAt: dto.createdAt.iso8601Date ?? Date(),
            updatedAt: dto.updatedAt.iso8601Date ?? Date()
        )
    }
    
    /// Convert local Message to API request
    static func toRequest(_ message: Message, volunteerIds: [String]? = nil) -> CreateMessageRequest {
        CreateMessageRequest(
            content: message.content,
            priority: message.priority.rawValue,
            recipientType: message.recipientType.rawValue,
            targetAssignmentId: message.targetAssignmentId,
            targetRoleId: message.targetRoleId,
            volunteerIds: volunteerIds,
            isQuickAlert: message.isQuickAlert,
            quickAlertType: message.quickAlertType
        )
    }
    
    // MARK: - AttendanceCount
    
    /// Convert AttendanceCountDTO from API to local AttendanceCount model
    static func toModel(_ dto: AttendanceCountDTO) -> AttendanceCount {
        AttendanceCount(
            id: dto.id,
            count: dto.count,
            countTime: dto.countTime.iso8601Date ?? Date(),
            notes: dto.notes,
            submittedAt: dto.submittedAt.iso8601Date ?? Date(),
            createdAt: dto.createdAt.iso8601Date ?? Date(),
            updatedAt: dto.updatedAt.iso8601Date ?? Date()
        )
    }
    
    /// Convert local AttendanceCount to API request
    static func toRequest(_ count: AttendanceCount) -> CreateAttendanceCountRequest {
        CreateAttendanceCountRequest(
            count: count.count,
            countTime: count.countTime.iso8601String,
            notes: count.notes,
            sessionId: count.session?.id ?? "",
            assignmentId: count.assignment?.id
        )
    }
}
