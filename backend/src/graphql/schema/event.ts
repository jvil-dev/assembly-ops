/**
 * GraphQL Event Schema
 *
 * Defines event management queries and mutations.
 *
 * Queries:
 *   - eventTemplates: Get available event templates (from HQ, seeded data)
 *   - myEvents: Get all events the current overseer has access to
 *   - myAllEvents: Get all events for the current user (overseer + volunteer)
 *   - event: Get a single event by ID
 *   - eventDepartments: Get all departments for an event
 *   - availableDepartments: Get department types not yet claimed
 *   - eventAdmins: Get all overseers for an event
 *   - discoverEvents: Get public events available to join
 *   - departmentInfo: Get detailed department info with hierarchy
 *
 * Mutations:
 *   - purchaseDepartment: Purchase a department in an event (creates EventAdmin + Department + access code)
 *   - joinDepartmentByAccessCode: Volunteer joins a department via access code
 *   - setDepartmentPrivacy: Toggle department public/private visibility
 *   - assignHierarchyRole: Assign a hierarchy role (e.g. ASSISTANT_OVERSEER) to a volunteer
 *   - removeHierarchyRole: Remove a hierarchy role assignment
 *
 * Department Purchase Flow:
 *   1. Events are pre-created (seeded or via admin panel)
 *   2. Overseer discovers event via discoverEvents
 *   3. Overseer calls purchaseDepartment → creates EventAdmin + Department + access code
 *   4. Volunteers join via access code or overseer invitation
 *
 * Implemented by: ../resolvers/event.ts
 */
const eventTypeDefs = `#graphql
  # ============================================
  # INPUTS
  # ============================================

  input PurchaseDepartmentInput {
    eventId: ID!
    departmentType: DepartmentType!
  }

  input JoinDepartmentByCodeInput {
    accessCode: String!
  }

  input AssignHierarchyRoleInput {
    departmentId: ID!
    eventVolunteerId: ID!
    hierarchyRole: HierarchyRole!
  }

  # ============================================
  # EVENT MEMBERSHIP (unified across roles)
  # ============================================

  enum UserEventMembershipType {
    OVERSEER
    VOLUNTEER
  }

  type UserEventMembership {
    eventId: ID!
    event: Event!
    membershipType: UserEventMembershipType!
    # Overseer-specific
    overseerRole: EventRole
    departmentId: ID
    departmentName: String
    departmentType: DepartmentType
    departmentAccessCode: String
    # Volunteer-specific
    eventVolunteerId: ID
    volunteerId: String
  }

  # ============================================
  # QUERIES & MUTATIONS
  # ============================================

  extend type Query {
    eventTemplates(serviceYear: Int): [EventTemplate!]!
    myEvents: [EventAdmin!]!
    myAllEvents: [UserEventMembership!]!
    event(id: ID!): Event
    eventDepartments(eventId: ID!): [Department!]!
    availableDepartments(eventId: ID!): [DepartmentType!]!
    eventAdmins(eventId: ID!): [EventAdmin!]!
    discoverEvents(eventType: EventType): [Event!]!
    departmentInfo(departmentId: ID!): Department
  }

  extend type Mutation {
    purchaseDepartment(input: PurchaseDepartmentInput!): Department!
    joinDepartmentByAccessCode(input: JoinDepartmentByCodeInput!): EventVolunteerCredentials!
    setDepartmentPrivacy(departmentId: ID!, isPublic: Boolean!): Department!
    assignHierarchyRole(input: AssignHierarchyRoleInput!): DepartmentHierarchy!
    removeHierarchyRole(departmentId: ID!, eventVolunteerId: ID!): Boolean!
  }
`;

export default eventTypeDefs;
