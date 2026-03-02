/**
 * Lanyard Tracking GraphQL Schema
 *
 * Type definitions for per-day lanyard pickup/return tracking.
 * Volunteers pick up lanyards before their shift and return them after.
 *
 * Types:
 *   - LanyardCheckout: Individual volunteer's lanyard status for a day
 *   - LanyardSummary: Aggregated stats for overseer view
 *
 * Queries:
 *   - myLanyardStatus(eventId, date?): Volunteer's own status today
 *   - lanyardStatuses(eventId, date?): All volunteers' statuses (overseer)
 *   - lanyardSummary(eventId, date?): Aggregate counts (overseer)
 *
 * Mutations:
 *   - pickUpLanyard(eventId): Volunteer picks up lanyard
 *   - returnLanyard(eventId): Volunteer returns lanyard
 *   - overseerPickUpLanyard(eventVolunteerId): Overseer marks pickup
 *   - overseerReturnLanyard(eventVolunteerId): Overseer marks return
 *
 * Used by: ./index.ts (schema composition)
 * Implemented by: ../resolvers/lanyard.ts
 */
export const lanyardTypeDefs = `#graphql
  # ============================================
  # TYPES
  # ============================================

  type LanyardCheckout {
    id: ID!
    eventVolunteerId: ID!
    eventId: ID!
    date: String!
    pickedUpAt: DateTime
    returnedAt: DateTime
    volunteerName: String!
  }

  type LanyardSummary {
    total: Int!
    pickedUp: Int!
    returned: Int!
    notPickedUp: Int!
  }

  # ============================================
  # QUERIES & MUTATIONS
  # ============================================

  extend type Query {
    myLanyardStatus(eventId: ID!, date: String): LanyardCheckout
    lanyardStatuses(eventId: ID!, date: String): [LanyardCheckout!]!
    lanyardSummary(eventId: ID!, date: String): LanyardSummary!
  }

  extend type Mutation {
    pickUpLanyard(eventId: ID!): LanyardCheckout!
    returnLanyard(eventId: ID!): LanyardCheckout!
    overseerPickUpLanyard(eventVolunteerId: ID!): LanyardCheckout!
    overseerReturnLanyard(eventVolunteerId: ID!): LanyardCheckout!
  }
`;
