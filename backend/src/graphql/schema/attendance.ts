/**
 * Attendance GraphQL Schema
 *
 * Type definitions for audience attendance count operations.
 * Used for CO-24 reporting with section-based counting.
 *
 * Types:
 *   - AttendanceCount: Count record with section, notes, submitter
 *   - SessionAttendanceSummary: Aggregated counts for a session
 *
 * Queries:
 *   - attendanceCount(id): Get single count by ID
 *   - sessionAttendanceCounts(sessionId): All counts for a session
 *   - sessionTotalAttendance(sessionId): Sum of all section counts
 *   - eventAttendanceSummary(eventId): Aggregated counts per session
 *
 * Mutations:
 *   - submitAttendanceCount: Record count for session/section (upserts)
 *   - updateAttendanceCount: Modify existing count
 *   - deleteAttendanceCount: Remove count record
 *
 * Used by: ./index.ts (schema composition)
 * Implemented by: ../resolvers/attendance.ts
 */
const attendanceTypeDefs = `#graphql
  # ============================================
  # INPUTS
  # ============================================

  input SubmitAttendanceCountInput {
    sessionId: ID!
    section: String
    postId: ID
    count: Int!
    notes: String
  }

  input UpdateAttendanceCountInput {
    count: Int
    notes: String
  }

  # ============================================
  # TYPES
  # ============================================

  type SessionAttendanceSummary {
    session: Session!
    totalCount: Int!
    sectionCounts: [AttendanceCount!]!
  }

  # ============================================
  # QUERIES & MUTATIONS
  # ============================================

  extend type Query {
    attendanceCount(id: ID!): AttendanceCount
    sessionAttendanceCounts(sessionId: ID!): [AttendanceCount!]!
    sessionTotalAttendance(sessionId: ID!): Int!
    eventAttendanceCounts(eventId: ID!): [AttendanceCount!]!
    eventAttendanceSummary(eventId: ID!): [SessionAttendanceSummary!]!
    volunteerSessionsForEvent(eventId: ID!): [Session!]!
    postAttendanceCounts(postId: ID!): [AttendanceCount!]!
  }

  extend type Mutation {
    submitAttendanceCount(input: SubmitAttendanceCountInput!): AttendanceCount!
    updateAttendanceCount(id: ID!, input: UpdateAttendanceCountInput!): AttendanceCount!
    deleteAttendanceCount(id: ID!): Boolean!
  }
`;

export default attendanceTypeDefs;
