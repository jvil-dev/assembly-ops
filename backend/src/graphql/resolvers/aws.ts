/**
 * AWS Resolvers
 *
 * Handles infrastructure monitoring queries via AWS SDK.
 * All operations require isAppAdmin via requireAppAdmin guard.
 *
 * Schema: ../schema/aws.ts
 */
import { Context } from '../context.js';
import { AwsService } from '../../services/awsService.js';
import { requireAppAdmin } from '../guards/auth.js';

const awsResolvers = {
  Query: {
    ecsServiceStatus: async (_parent: unknown, _args: unknown, context: Context) => {
      requireAppAdmin(context);
      return new AwsService(context.prisma).getEcsServiceStatus();
    },

    cloudwatchMetrics: async (_parent: unknown, { period, metricName }: { period: string; metricName: string }, context: Context) => {
      requireAppAdmin(context);
      return new AwsService(context.prisma).getCloudwatchMetrics(period, metricName);
    },

    cloudwatchLogs: async (_parent: unknown, { limit, filterPattern }: { limit?: number; filterPattern?: string }, context: Context) => {
      requireAppAdmin(context);
      return new AwsService(context.prisma).getCloudwatchLogs(limit, filterPattern);
    },

    awsCostBreakdown: async (_parent: unknown, { startDate, endDate }: { startDate: string; endDate: string }, context: Context) => {
      requireAppAdmin(context);
      return new AwsService(context.prisma).getAwsCostBreakdown(startDate, endDate);
    },

    databaseStats: async (_parent: unknown, _args: unknown, context: Context) => {
      requireAppAdmin(context);
      return new AwsService(context.prisma).getDatabaseStats();
    },
  },
};

export default awsResolvers;
