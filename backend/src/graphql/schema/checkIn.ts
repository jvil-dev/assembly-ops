/**
 * GraphQL Check-In Schema
 *
 * Defines check-in and attendance queries and mutations.
 *
 * Types:
 *   - CheckInStats: Aggregated check-in statistics for a session
 *
 * Queries:
 *   - checkIn: Get a check-in record by ID (admin)
 *   - sessionCheckIns: Get all check-ins for a session (admin)
 *   - checkInStats: Get check-in statistics for a session (admin)
 *   - attendanceCount: Get audience count for a session (admin)
 *   - eventAttendanceCounts: Get all attendance counts for an event (admin)
 *
 * Mutations:
 *   - checkIn: Volunteer checks in to their assignment
 *   - checkOut: Volunteer checks out of their assignment
 *   - adminCheckIn: Admin checks in a volunteer on their behalf
 *   - markNoShow: Admin marks a volunteer as no-show
 *   - recordAttendance: Record audience count for CO-24 (EVENT_OVERSEER)
 *   - updateAttendance: Update audience count (EVENT_OVERSEER)
 *   - deleteAttendance: Delete audience count (EVENT_OVERSEER)
 *
 * Implemented by: ../resolvers/checkIn.ts
 */
const checkInTypeDefs = `#graphql
    # ============================================
    # TYPES
    # ============================================

    type CheckInStats {
    sessionId: ID!
    totalAssignments: Int!
    checkedIn: Int!
    checkedOut: Int!
    noShow: Int!
    pending: Int!
    }

    # ============================================
    # INPUTS
    # ============================================

    input CheckInInput {
    assignmentId: ID!
    }

    input CheckOutInput {
    assignmentId: ID!
    }

    input AdminCheckInInput {
    assignmentId: ID!
    notes: String
    }

    input MarkNoShowInput {
    assignmentId: ID!
    notes: String
    }

    input RecordAttendanceInput {
    sessionId: ID!
    count: Int!
    notes: String
    }

    input UpdateAttendanceInput {
    count: Int
    notes: String
    }

    # ============================================
    # QUERIES & MUTATIONS
    # ============================================

    extend type Query {
    checkIn(id: ID!): CheckIn
    sessionCheckIns(sessionId: ID!): [CheckIn!]!
    checkInStats(sessionId: ID!): CheckInStats!
    attendanceCount(sessionId: ID!): AttendanceCount
    eventAttendanceCounts(eventId: ID!): [AttendanceCount!]!
    }

    extend type Mutation {
    # Volunteer actions
    checkIn(input: CheckInInput!): CheckIn!
    checkOut(input: CheckOutInput!): CheckIn!

    # Admin actions
    adminCheckIn(input: AdminCheckInInput!): CheckIn!
    markNoShow(input: MarkNoShowInput!): CheckIn!

    # Attendance counts (admin only)
    recordAttendance(input: RecordAttendanceInput!): AttendanceCount!
    updateAttendance(id: ID!, input: UpdateAttendanceInput!): AttendanceCount!
    deleteAttendance(id: ID!): Boolean!
    }
`;

export default checkInTypeDefs;
