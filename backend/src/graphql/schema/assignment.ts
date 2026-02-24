/**
 * Assignment GraphQL Schema
 *
 * Type definitions for schedule assignments, acceptance workflow, and captain role.
 * This is where department overseers manage volunteer scheduling.
 *
 * Enums:
 *   - AssignmentStatus: PENDING, ACCEPTED, DECLINED, AUTO_DECLINED
 *
 * Types:
 *   - ScheduleAssignment: Extended with status, isCaptain, respondedAt, etc.
 *   - CoverageSlot: One cell in the posts × sessions grid (ACCEPTED + PENDING)
 *   - CoveragePost/Session/Volunteer/CheckIn: Lightweight types for matrix
 *
 * Queries:
 *   - assignment(id), assignments(eventId): Get assignments
 *   - volunteerAssignments, sessionAssignments, postAssignments: Filtered
 *   - myAssignments(status?): Volunteer's schedule with optional status filter
 *   - pendingAssignments(filter): Get PENDING assignments for event/department
 *   - declinedAssignments(eventId): Get DECLINED/AUTO_DECLINED assignments
 *   - captainGroup(assignmentId): Volunteers at same post/session as captain
 *   - departmentCoverage, departmentCoverageGaps: Coverage matrix
 *
 * Mutations:
 *   - createAssignment: Create with PENDING status
 *   - acceptAssignment, declineAssignment: Volunteer response
 *   - forceAssignment: Admin bypasses acceptance (auto-ACCEPTED)
 *   - setCaptain: Designate assignment as captain
 *   - captainCheckIn: Captain checks in group member
 *   - updateAssignment, deleteAssignment: Modify or remove
 *
 * Used by: ./index.ts (schema composition)
 * Implemented by: ../resolvers/assignment.ts
 */
const assignmentTypeDefs = `#graphql
  # ============================================
  # ENUMS
  # ============================================

  enum AssignmentStatus {
    PENDING
    ACCEPTED
    DECLINED
    AUTO_DECLINED
  }

  # ============================================
  # TYPES
  # ============================================

  type CoverageSlot {
    post: CoveragePost!
    session: CoverageSession!
    assignments: [CoverageAssignment!]!
    filled: Int!
    capacity: Int!
    isFilled: Boolean!
  }

  type CoveragePost {
    id: ID!
    name: String!
    capacity: Int!
    category: String
    location: String
    sortOrder: Int!
    areaId: ID
    areaName: String
  }

  type CoverageSession {
    id: ID!
    name: String!
    date: DateTime!
    startTime: DateTime!
    endTime: DateTime!
  }

  type CoverageAssignment {
    id: ID!
    volunteer: CoverageVolunteer!
    checkIn: CoverageCheckIn
    status: AssignmentStatus!
    forceAssigned: Boolean!
  }

  type CoverageVolunteer {
    id: ID!
    firstName: String!
    lastName: String!
  }

  type CoverageCheckIn {
    id: ID!
    checkInTime: DateTime!
  }

  type ScheduleAssignment {
    id: ID!
    volunteer: Volunteer!
    post: Post!
    session: Session!
    status: AssignmentStatus!
    isCaptain: Boolean!
    respondedAt: DateTime
    declineReason: String
    acceptDeadline: DateTime
    forceAssigned: Boolean!
    checkIn: CheckIn
    createdAt: DateTime!
    updatedAt: DateTime!
  }

  type CaptainGroup {
    captain: ScheduleAssignment!
    members: [ScheduleAssignment!]!
  }

  # ============================================
  # INPUTS
  # ============================================

  input CreateAssignmentInput {
    volunteerId: ID!
    postId: ID!
    sessionId: ID!
    isCaptain: Boolean
  }

  input UpdateAssignmentInput {
    postId: ID
    isCaptain: Boolean
  }

  input AcceptAssignmentInput {
    assignmentId: ID!
  }

  input DeclineAssignmentInput {
    assignmentId: ID!
    reason: String
  }

  input ForceAssignmentInput {
    volunteerId: ID!
    postId: ID!
    sessionId: ID!
    isCaptain: Boolean
  }

  input SetCaptainInput {
    assignmentId: ID!
    isCaptain: Boolean!
  }

  input CaptainCheckInInput {
    assignmentId: ID!
    notes: String
  }

  input PendingAssignmentsFilter {
    eventId: ID
    departmentId: ID
    status: AssignmentStatus
  }

  # ============================================
  # QUERIES & MUTATIONS
  # ============================================

  extend type Query {
    assignment(id: ID!): ScheduleAssignment
    assignments(eventId: ID, departmentId: ID, sessionId: ID, volunteerId: ID): [ScheduleAssignment!]!
    volunteerAssignments(volunteerId: ID!): [ScheduleAssignment!]!
    sessionAssignments(sessionId: ID!): [ScheduleAssignment!]!
    postAssignments(postId: ID!): [ScheduleAssignment!]!
    myAssignments(status: AssignmentStatus): [ScheduleAssignment!]!
    pendingAssignments(filter: PendingAssignmentsFilter): [ScheduleAssignment!]!
    declinedAssignments(eventId: ID, departmentId: ID): [ScheduleAssignment!]!
    captainGroup(postId: ID!, sessionId: ID!): CaptainGroup
    departmentCoverage(departmentId: ID!): [CoverageSlot!]!
    departmentCoverageGaps(departmentId: ID!): [CoverageSlot!]!
  }

  extend type Mutation {
    createAssignment(input: CreateAssignmentInput!): ScheduleAssignment!
    updateAssignment(id: ID!, input: UpdateAssignmentInput!): ScheduleAssignment!
    deleteAssignment(id: ID!): Boolean!
    bulkCreateAssignments(inputs: [CreateAssignmentInput!]!): [ScheduleAssignment!]!

    acceptAssignment(input: AcceptAssignmentInput!): ScheduleAssignment!
    declineAssignment(input: DeclineAssignmentInput!): ScheduleAssignment!

    forceAssignment(input: ForceAssignmentInput!): ScheduleAssignment!
    setCaptain(input: SetCaptainInput!): ScheduleAssignment!
    setAcceptDeadline(assignmentId: ID!, deadline: DateTime!): ScheduleAssignment!

    captainCheckIn(input: CaptainCheckInInput!): ScheduleAssignment!
  }
`;

export default assignmentTypeDefs;
