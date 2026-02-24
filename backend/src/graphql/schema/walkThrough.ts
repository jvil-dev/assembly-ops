/**
 * Walk-Through Completion GraphQL Schema
 *
 * Type definitions for walk-through checklist persistence.
 * Captains complete walk-throughs before sessions and submit results.
 *
 * Types:
 *   - WalkThroughCompletion: Completion record with session, volunteer, item count
 *
 * Queries:
 *   - walkThroughCompletions(eventId, sessionId?): All completions for an event
 *   - myWalkThroughCompletions: Volunteer's own completions
 *
 * Mutations:
 *   - submitWalkThroughCompletion: Record walk-through completion
 *
 * Used by: ../resolvers/walkThrough.ts
 */
export const walkThroughTypeDefs = `#graphql
  type WalkThroughCompletion {
    id: ID!
    event: Event!
    session: Session!
    eventVolunteer: EventVolunteer!
    completedAt: String!
    itemCount: Int!
    notes: String
  }

  input SubmitWalkThroughCompletionInput {
    eventId: ID!
    sessionId: ID!
    itemCount: Int!
    notes: String
  }

  extend type Query {
    walkThroughCompletions(eventId: ID!, sessionId: ID): [WalkThroughCompletion!]!
    myWalkThroughCompletions: [WalkThroughCompletion!]!
  }

  extend type Mutation {
    submitWalkThroughCompletion(input: SubmitWalkThroughCompletionInput!): WalkThroughCompletion!
  }
`;
