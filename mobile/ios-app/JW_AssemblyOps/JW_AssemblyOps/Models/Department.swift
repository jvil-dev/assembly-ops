//
//  Department.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/22/25.
//


import Foundation
import SwiftData

@Model
final class Department {
    // MARK: - Properties
    
    @Attribute(.unique) var id: String
    var departmentType: DepartmentType
    var overseerId: String?  // Admin ID of department overseer
    var overseerName: String?
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    var lastSyncedAt: Date?
    
    // MARK: - Relationships
    
    var event: Event?
    
    @Relationship(deleteRule: .nullify, inverse: \Volunteer.department)
    var volunteers: [Volunteer]?
    
    @Relationship(deleteRule: .cascade, inverse: \Assignment.department)
    var assignments: [Assignment]?
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        departmentType: DepartmentType,
        overseerId: String? = nil,
        overseerName: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.departmentType = departmentType
        self.overseerId = overseerId
        self.overseerName = overseerName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var displayName: String {
        departmentType.displayName
    }
    
    var volunteerCount: Int {
        volunteers?.count ?? 0
    }
    
    var assignmentCount: Int {
        assignments?.count ?? 0
    }
}
