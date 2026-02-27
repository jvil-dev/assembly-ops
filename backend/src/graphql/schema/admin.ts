/**
 * GraphQL Admin Schema
 *
 * Defines app-admin queries and mutations for data import and analytics.
 * All operations require the `isAppAdmin` flag on the authenticated user.
 *
 * Implemented by: ../resolvers/admin.ts
 */
const adminTypeDefs = `#graphql
  type ImportError {
    row: Int!
    field: String!
    message: String!
  }

  type ImportResult {
    success: Boolean!
    created: Int!
    updated: Int!
    skipped: Int!
    totalRows: Int!
    errors: [ImportError!]!
  }

  type AppAnalytics {
    totalUsers: Int!
    totalOverseers: Int!
    totalEvents: Int!
    totalVolunteers: Int!
    totalAssignments: Int!
    totalCheckIns: Int!
  }

  type GrowthDataPoint {
    date: DateTime!
    count: Int!
  }

  type EventStat {
    eventId: ID!
    name: String!
    eventType: EventType!
    startDate: DateTime!
    volunteerCount: Int!
    departmentCount: Int!
    sessionCount: Int!
  }

  extend type Query {
    appAnalytics: AppAnalytics!
    userGrowth(period: String!): [GrowthDataPoint!]!
    eventStats: [EventStat!]!
  }

  extend type Mutation {
    importCongregations(csvData: String!): ImportResult!
    importEvents(csvData: String!): ImportResult!
    importVolunteers(eventId: ID!, csvData: String!): ImportResult!
  }
`;

export default adminTypeDefs;
