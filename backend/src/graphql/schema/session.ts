/**
 * Session GraphQL Schema
 *
 * Type definitions for session operations.
 * Sessions are event-wide time blocks (e.g., "Friday Morning", "Saturday Afternoon").
 * All departments share the same sessions within an event.
 *
 * Inputs:
 *   - CreateSessionInput: name, date (required); startTime, endTime (optional, default "00:00"/"23:59")
 *   - CreateSessionsInput: eventId + array of sessions (bulk creation)
 *   - UpdateSessionInput: All fields optional (patch-style update)
 *   - UpsertDepartmentSessionInput: Optional department-level time override and notes
 *
 * Time Format:
 *   startTime/endTime use "HH:MM" 24-hour format (e.g., "09:00", "14:30")
 *
 * Queries:
 *   - session(id): Single session by ID
 *   - sessions(eventId, departmentId): All sessions for an event (departmentId scopes assignmentCount)
 *
 * Mutations: createSession, createSessions, updateSession, deleteSession, upsertDepartmentSession
 */
const sessionTypeDefs = `#graphql
  # ============================================
  # INPUTS
  # ============================================

  input CreateSessionInput {
    name: String!
    date: DateTime!
    startTime: String
    endTime: String
  }

  input CreateSessionsInput {
    eventId: ID!
    sessions: [CreateSessionInput!]!
  }

  input UpdateSessionInput {
    name: String
    date: DateTime
    startTime: String
    endTime: String
  }

  input UpsertDepartmentSessionInput {
    startTime: String
    endTime: String
    notes: String
  }

  # ============================================
  # TYPES
  # ============================================

  type DepartmentSession {
    id: ID!
    departmentId: ID!
    sessionId: ID!
    startTime: DateTime
    endTime: DateTime
    notes: String
  }

  # ============================================
  # QUERIES & MUTATIONS
  # ============================================

  extend type Query {
    session(id: ID!): Session
    sessions(eventId: ID!, departmentId: ID): [Session!]!
  }

  extend type Mutation {
    createSession(eventId: ID!, input: CreateSessionInput!): Session!
    createSessions(input: CreateSessionsInput!): [Session!]!
    updateSession(id: ID!, input: UpdateSessionInput!): Session!
    deleteSession(id: ID!): Boolean!
    upsertDepartmentSession(departmentId: ID!, sessionId: ID!, input: UpsertDepartmentSessionInput!): DepartmentSession!
  }
`;

export default sessionTypeDefs;
