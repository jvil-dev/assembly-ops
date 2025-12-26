/**
 * GraphQL Schema Composition
 *
 * This file combines all the GraphQL type definitions into a single schema.
 * Think of it as the "table of contents" for your API.
 *
 * Schema files define WHAT your API can do:
 *   - types.ts: Core types (Event, Volunteer, Department, Post, Session, etc.)
 *   - auth.ts: Authentication queries/mutations (login, register, logout)
 *   - event.ts: Event management (activate, join, claim department)
 *   - volunteer.ts: Volunteer management (create, update, delete, login)
 *
 * The baseTypeDefs here defines:
 *   - DateTime scalar: Custom type for timestamps
 *   - Query root: Starting point for all queries
 *   - Mutation root: Starting point for all mutations
 *   - health: Basic health check query
 *
 * Used by: ./index.ts (Apollo Server setup)
 * Implemented by: ../resolvers/ (the actual logic)
 */
import types from './types.js';
import authTypeDefs from './auth.js';
import eventTypeDefs from './event.js';
import volunteerTypeDefs from './volunteer.js';
import postTypeDefs from './post.js';
import sessionTypeDefs from './session.js';

const baseTypeDefs = `#graphql
  scalar DateTime

  type Query {
    health: HealthStatus!
  }

  type Mutation {
    _empty: String
  }

  type HealthStatus {
    status: String!
    timestamp: DateTime!
    database: String!
  }
`;

const typeDefs = [
  baseTypeDefs,
  types,
  authTypeDefs,
  eventTypeDefs,
  volunteerTypeDefs,
  postTypeDefs,
  sessionTypeDefs,
];

export default typeDefs;
