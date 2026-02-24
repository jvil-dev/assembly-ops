/**
 * Post Session Status GraphQL Schema
 *
 * Type definitions for seating section status management.
 * Attendants toggle section status between OPEN, FILLING, and FULL.
 *
 * Types:
 *   - PostSessionStatus: Status record with post, session, status
 *
 * Queries:
 *   - postSessionStatuses(sessionId): All statuses for a session
 *   - eventPostSessionStatuses(eventId): All statuses for an event
 *
 * Mutations:
 *   - updatePostSessionStatus: Upsert a post/session status
 *
 * Used by: ../resolvers/postSessionStatus.ts
 */
export const postSessionStatusTypeDefs = `#graphql
  enum SeatingSectionStatus {
    OPEN
    FILLING
    FULL
  }

  type PostSessionStatus {
    id: ID!
    post: Post!
    session: Session!
    status: SeatingSectionStatus!
    updatedBy: EventVolunteer!
    updatedAt: String!
  }

  input UpdatePostSessionStatusInput {
    postId: ID!
    sessionId: ID!
    status: SeatingSectionStatus!
  }

  extend type Query {
    postSessionStatuses(sessionId: ID!): [PostSessionStatus!]!
    eventPostSessionStatuses(eventId: ID!): [PostSessionStatus!]!
  }

  extend type Mutation {
    updatePostSessionStatus(input: UpdatePostSessionStatusInput!): PostSessionStatus!
  }
`;
