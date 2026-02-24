//
//  VolunteerListItem.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Volunteer List Item
//
// Lightweight volunteer model for list displays in overseer views.
// Used by VolunteerListView, VolunteerPickerSheet, and VolunteerDetailView.
//
// Properties:
//   - id: Internal database ID
//   - volunteerId: Human-readable volunteer ID for login
//   - fullName/firstName/lastName: Display name variations
//   - congregation: Home congregation
//   - phone/email: Optional contact info
//   - appointmentStatus: PUBLISHER, MINISTERIAL_SERVANT, or ELDER
//   - departmentId/departmentName: Assigned department (optional)
//   - roleName: Assigned role within department (optional)
//
// Usage:
//   - VolunteersViewModel maps GraphQL response to this model
//   - Displayed in volunteer lists and detail views
//   - Used for volunteer selection in assignment workflows
//

import Foundation

struct VolunteerListItem: Identifiable {
    let id: String
    let volunteerId: String
    let fullName: String
    let firstName: String
    let lastName: String
    let congregation: String
    let phone: String?
    let email: String?
    let appointmentStatus: String?
    let departmentId: String?
    let departmentName: String?
    let departmentType: String?
    let roleId: String?
    let roleName: String?
}

struct RoleItem: Identifiable {
    let id: String
    let name: String
    let sortOrder: Int
}
