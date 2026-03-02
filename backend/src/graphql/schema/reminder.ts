/**
 * Reminder Confirmation GraphQL Schema
 *
 * Type definitions for mandatory shift/session reminder confirmations.
 * Attendant volunteers must read and confirm CO-23 reminders before each shift.
 *
 * Types:
 *   - ReminderConfirmation: Record of a volunteer confirming a reminder
 *   - ShiftReminderStatus: Per-shift compliance summary for overseers
 *
 * Queries:
 *   - myReminderConfirmations(eventId): Volunteer's own confirmations
 *   - shiftReminderStatus(shiftId): Compliance view for overseer
 *
 * Mutations:
 *   - confirmShiftReminder(shiftId): Volunteer confirms shift reminder
 *   - confirmSessionReminder(sessionId): Fallback for non-shift departments
 *
 * Used by: ./index.ts (schema composition)
 * Implemented by: ../resolvers/reminder.ts
 */
export const reminderTypeDefs = `#graphql
  # ============================================
  # TYPES
  # ============================================

  type ReminderConfirmation {
    id: ID!
    eventVolunteerId: ID!
    shiftId: ID
    sessionId: ID
    confirmedAt: DateTime!
  }

  type ShiftReminderStatus {
    shiftId: ID!
    shiftName: String!
    totalAssigned: Int!
    totalConfirmed: Int!
    confirmations: [ReminderVolunteerStatus!]!
  }

  type ReminderVolunteerStatus {
    eventVolunteerId: ID!
    firstName: String!
    lastName: String!
    confirmed: Boolean!
    confirmedAt: DateTime
  }

  # ============================================
  # QUERIES & MUTATIONS
  # ============================================

  extend type Query {
    myReminderConfirmations(eventId: ID!): [ReminderConfirmation!]!
    shiftReminderStatus(shiftId: ID!): ShiftReminderStatus!
  }

  extend type Mutation {
    confirmShiftReminder(shiftId: ID!): ReminderConfirmation!
    confirmSessionReminder(sessionId: ID!): ReminderConfirmation!
  }
`;
