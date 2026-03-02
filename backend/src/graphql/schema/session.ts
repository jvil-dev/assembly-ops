/**
 * Session GraphQL Schema
 *
 * Type definitions for session operations.
 * Sessions are event-wide time blocks (e.g., "Friday Morning", "Saturday Afternoon").
 * All departments share the same sessions within an event.
 *
 * Inputs:
 *   - CreateSessionInput: name, date, startTime, endTime (all required)
 *   - CreateSessionsInput: eventId + array of sessions (bulk creation)
 *   - UpdateSessionInput: All fields optional (patch-style update)
 *
 * Time Format:
 *   startTime/endTime use "HH:MM" 24-hour format (e.g., "09:00", "14:30")
 *
 * Queries:
 *   - session(id): Single session by ID
 *   - sessions(eventId): All sessions for an event
 *
 * Mutations: createSession, createSessions, updateSession, deleteSession
 */
const sessionTypeDefs = `#graphql
  # ============================================
  # INPUTS
  # ============================================

  input CreateSessionInput {
    name: String!
    date: DateTime!
    startTime: String!
    endTime: String!
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

  # ============================================
  # QUERIES & MUTATIONS
  # ============================================

  extend type Query {
    session(id: ID!): Session
    sessions(eventId: ID!): [Session!]!
  }

  extend type Mutation {
    createSession(eventId: ID!, input: CreateSessionInput!): Session!
    createSessions(input: CreateSessionsInput!): [Session!]!
    updateSession(id: ID!, input: UpdateSessionInput!): Session!
    deleteSession(id: ID!): Boolean!
  }
`;

export default sessionTypeDefs;
