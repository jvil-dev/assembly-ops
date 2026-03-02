/**
 * Shift GraphQL Schema
 *
 * Type definitions for shift operations.
 * Shifts subdivide sessions into custom time blocks (e.g., 1-hour exterior attendant shifts
 * within a 3-hour session). Shift times are free-form — NOT constrained to the parent
 * session's program times — since departments like Attendant and Parking start duty
 * well before the program begins.
 *
 * Inputs:
 *   - CreateShiftInput: sessionId, postId, startTime (HH:MM), endTime (HH:MM)
 *   - UpdateShiftInput: startTime, endTime (all optional); name is auto-generated
 *
 * Queries:
 *   - shifts(sessionId, postId?): Shifts for a session, optionally filtered by post
 *
 * Mutations: createShift, updateShift, deleteShift
 *
 * Used by: ./index.ts (schema composition)
 * Implemented by: ../resolvers/shift.ts
 */
export const shiftTypeDefs = `#graphql
  # ============================================
  # TYPES
  # ============================================

  type Shift {
    id: ID!
    session: Session!
    post: Post!
    name: String!
    startTime: DateTime!
    endTime: DateTime!
    assignments: [ScheduleAssignment!]!
    createdBy: User
    createdAt: DateTime!
  }

  # ============================================
  # INPUTS
  # ============================================

  input CreateShiftInput {
    sessionId: ID!
    postId: ID!
    startTime: String!
    endTime: String!
  }

  input UpdateShiftInput {
    startTime: String
    endTime: String
  }

  # ============================================
  # QUERIES & MUTATIONS
  # ============================================

  extend type Query {
    shifts(sessionId: ID!, postId: ID): [Shift!]!
  }

  extend type Mutation {
    createShift(input: CreateShiftInput!): Shift!
    updateShift(id: ID!, input: UpdateShiftInput!): Shift!
    deleteShift(id: ID!): Boolean!
  }
`;
