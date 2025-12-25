import types from './types.js';

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

const typeDefs = [baseTypeDefs, types];

export default typeDefs;
