/**
 * GraphQL GCP Schema
 *
 * Defines admin queries for GCP infrastructure monitoring.
 * All operations require the `isAppAdmin` flag on the authenticated user.
 *
 * Implemented by: ../resolvers/gcp.ts
 */
const gcpTypeDefs = `#graphql
  type CloudRunServiceStatus {
    status: String!
    latestRevision: String
    cpuLimit: String
    memoryLimit: String
    minInstances: Int!
    maxInstances: Int!
  }

  type MetricDataPoint {
    timestamp: String!
    value: Float!
  }

  type LogEvent {
    timestamp: String
    message: String!
    logStreamName: String!
  }

  type CostEntry {
    service: String!
    amount: Float!
    unit: String!
    timePeriodStart: String!
    timePeriodEnd: String!
  }

  type TableCounts {
    users: Int!
    events: Int!
    eventVolunteers: Int!
    assignments: Int!
    checkIns: Int!
  }

  type DatabaseStats {
    databaseSize: String!
    activeConnections: Int!
    tableCounts: TableCounts!
  }

  extend type Query {
    cloudRunServiceStatus: CloudRunServiceStatus!
    gcpMetrics(period: String!, metricName: String!): [MetricDataPoint!]!
    gcpLogs(limit: Int, filter: String): [LogEvent!]!
    gcpCostBreakdown(startDate: String!, endDate: String!): [CostEntry!]!
    databaseStats: DatabaseStats!
  }
`;

export default gcpTypeDefs;
