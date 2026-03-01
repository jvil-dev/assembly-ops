/**
 * Captain Scheduling Schema
 *
 * Captain-specific mutations for attendant department scheduling.
 * Captains can create/delete assignments, swap volunteers, and manage shifts
 * within their department scope.
 *
 * These are separate mutations from the overseer ones to maintain clear
 * authorization boundaries. Captain mutations delegate to the same
 * underlying service methods but enforce department-scope validation.
 *
 * Used by: ./index.ts (schema composition)
 */
import { gql } from 'graphql-tag';

export const captainSchedulingTypeDefs = gql`
  input CaptainCreateAssignmentInput {
    eventId: ID!
    eventVolunteerId: ID!
    postId: ID!
    sessionId: ID!
    shiftId: ID
  }

  input CaptainSwapInput {
    assignmentId: ID!
    newEventVolunteerId: ID!
  }

  input CaptainCreateShiftInput {
    eventId: ID!
    sessionId: ID!
    postId: ID!
    startTime: String!
    endTime: String!
  }

  input CaptainUpdateShiftInput {
    eventId: ID!
    startTime: String
    endTime: String
  }

  extend type Query {
    captainSessions(eventId: ID!): [Session!]!
    captainShifts(sessionId: ID!, postId: ID): [Shift!]!
    captainVolunteers(eventId: ID!, departmentId: ID!): [EventVolunteer!]!
    captainPosts(departmentId: ID!): [Post!]!
  }

  extend type Mutation {
    captainCreateAssignment(input: CaptainCreateAssignmentInput!): ScheduleAssignment!
    captainDeleteAssignment(eventId: ID!, assignmentId: ID!): Boolean!
    captainSwapVolunteer(input: CaptainSwapInput!, eventId: ID!): ScheduleAssignment!
    captainCreateShift(input: CaptainCreateShiftInput!): Shift!
    captainUpdateShift(id: ID!, input: CaptainUpdateShiftInput!): Shift!
    captainDeleteShift(id: ID!, eventId: ID!): Boolean!
  }
`;
