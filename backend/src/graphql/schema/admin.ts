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

  type AdminUser {
    id: ID!
    userId: String!
    email: String!
    firstName: String!
    lastName: String!
    isOverseer: Boolean!
    isAppAdmin: Boolean!
    createdAt: DateTime!
    eventCount: Int!
  }

  type AdminUserList {
    users: [AdminUser!]!
    totalCount: Int!
  }

  type AdminEventDetail {
    eventId: ID!
    name: String!
    eventType: EventType!
    startDate: DateTime!
    endDate: DateTime!
    venue: String!
    state: String
    volunteerCount: Int!
    departmentCount: Int!
    sessionCount: Int!
    overseerCount: Int!
  }

  type AdminEventList {
    events: [AdminEventDetail!]!
    totalCount: Int!
  }

  extend type Query {
    appAnalytics: AppAnalytics!
    userGrowth(period: String!): [GrowthDataPoint!]!
    eventStats: [EventStat!]!
    adminListUsers(limit: Int, offset: Int, search: String): AdminUserList!
    adminListEvents(limit: Int, offset: Int): AdminEventList!
  }

  extend type Mutation {
    importCongregations(csvData: String!): ImportResult!
    importEvents(csvData: String!): ImportResult!
    importVolunteers(eventId: ID!, csvData: String!): ImportResult!
  }
`;

export default adminTypeDefs;
