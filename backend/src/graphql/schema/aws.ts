/**
 * GraphQL AWS Schema
 *
 * Defines admin queries for AWS infrastructure monitoring.
 * All operations require the `isAppAdmin` flag on the authenticated user.
 *
 * Implemented by: ../resolvers/aws.ts
 */
const awsTypeDefs = `#graphql
  type EcsServiceStatus {
    runningCount: Int!
    desiredCount: Int!
    pendingCount: Int!
    status: String!
    lastDeploymentAt: String
    lastDeploymentStatus: String
    cpuReservation: Int
    memoryReservation: Int
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
    ecsServiceStatus: EcsServiceStatus!
    cloudwatchMetrics(period: String!, metricName: String!): [MetricDataPoint!]!
    cloudwatchLogs(limit: Int, filterPattern: String): [LogEvent!]!
    awsCostBreakdown(startDate: String!, endDate: String!): [CostEntry!]!
    databaseStats: DatabaseStats!
  }
`;

export default awsTypeDefs;
