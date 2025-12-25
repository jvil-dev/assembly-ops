import types from './types.js';
import authTypeDefs from './auth.js';
import eventTypeDefs from './event.js';
import volunteerTypeDefs from './volunteer.js';

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

const typeDefs = [baseTypeDefs, types, authTypeDefs, eventTypeDefs, volunteerTypeDefs];

export default typeDefs;
