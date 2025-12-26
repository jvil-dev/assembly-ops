/**
 * Assignment GraphQL Schema
 *
 * Type definitions for schedule assignments and coverage matrix queries.
 * This is where department overseers manage volunteer scheduling.
 *
 * Types:
 *   - CoverageSlot: One cell in the posts × sessions grid
 *   - CoveragePost/Session/Volunteer/CheckIn: Lightweight types for coverage matrix
 *
 * Queries:
 *   - assignment(id): Get single assignment
 *   - assignments(eventId): All assignments for an event
 *   - volunteerAssignments(volunteerId): A volunteer's schedule
 *   - sessionAssignments(sessionId): Who's assigned to a session
 *   - postAssignments(postId): Who's assigned to a post
 *   - myAssignments: Volunteer's own schedule (volunteer auth)
 *   - departmentCoverage(departmentId): Full coverage matrix
 *   - departmentCoverageGaps(departmentId): Only unfilled slots
 *
 * Mutations:
 *   - createAssignment: Assign one volunteer to post+session
 *   - createAssignments: Bulk assign multiple volunteers
 *   - updateAssignment: Change post or session
 *   - deleteAssignment: Remove an assignment
 *
 * Used by: ./index.ts (schema composition)
 * Implemented by: ../resolvers/assignment.ts
 */
const assignmentTypeDefs = `#graphql
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

  # ============================================
  # INPUTS
  # ============================================

  input CreateAssignmentInput {
    volunteerId: ID!
    postId: ID!
    sessionId: ID!
  }

  input CreateAssignmentsInput {
    assignments: [CreateAssignmentInput!]!
  }

  input UpdateAssignmentInput {
    postId: ID
    sessionId: ID
  }

  # ============================================
  # QUERIES & MUTATIONS
  # ============================================

  extend type Query {
    assignment(id: ID!): ScheduleAssignment
    assignments(eventId: ID!): [ScheduleAssignment!]!
    volunteerAssignments(volunteerId: ID!): [ScheduleAssignment!]!
    sessionAssignments(sessionId: ID!): [ScheduleAssignment!]!
    postAssignments(postId: ID!): [ScheduleAssignment!]!
    myAssignments: [ScheduleAssignment!]!
    departmentCoverage(departmentId: ID!): [CoverageSlot!]!
    departmentCoverageGaps(departmentId: ID!): [CoverageSlot!]!
  }

  extend type Mutation {
    createAssignment(input: CreateAssignmentInput!): ScheduleAssignment!
    createAssignments(input: CreateAssignmentsInput!): [ScheduleAssignment!]!
    updateAssignment(id: ID!, input: UpdateAssignmentInput!): ScheduleAssignment!
    deleteAssignment(id: ID!): Boolean!
  }
`;

export default assignmentTypeDefs;
