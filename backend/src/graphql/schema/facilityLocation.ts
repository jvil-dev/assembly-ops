/**
 * Facility Location GraphQL Schema
 *
 * Type definitions for facility location guide management.
 * Overseers create reference locations (restrooms, first aid, exits, etc.)
 * that volunteers can view during the event.
 *
 * Types:
 *   - FacilityLocation: Location record with name, location, description
 *
 * Queries:
 *   - facilityLocations(eventId): All locations for an event
 *
 * Mutations:
 *   - createFacilityLocation / updateFacilityLocation / deleteFacilityLocation
 *
 * Used by: ../resolvers/facilityLocation.ts
 */
export const facilityLocationTypeDefs = `#graphql
  type FacilityLocation {
    id: ID!
    event: Event!
    name: String!
    location: String!
    description: String
    sortOrder: Int!
  }

  input CreateFacilityLocationInput {
    eventId: ID!
    name: String!
    location: String!
    description: String
    sortOrder: Int
  }

  input UpdateFacilityLocationInput {
    name: String
    location: String
    description: String
    sortOrder: Int
  }

  extend type Query {
    facilityLocations(eventId: ID!): [FacilityLocation!]!
  }

  extend type Mutation {
    createFacilityLocation(input: CreateFacilityLocationInput!): FacilityLocation!
    updateFacilityLocation(id: ID!, input: UpdateFacilityLocationInput!): FacilityLocation!
    deleteFacilityLocation(id: ID!): Boolean!
  }
`;
