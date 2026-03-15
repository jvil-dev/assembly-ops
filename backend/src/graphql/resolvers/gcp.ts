/**
 * GCP Resolvers
 *
 * Handles infrastructure monitoring queries via GCP SDK.
 * All operations require isAppAdmin via requireAppAdmin guard.
 *
 * Schema: ../schema/gcp.ts
 */
import { Context } from '../context.js';
import { GcpService } from '../../services/gcpService.js';
import { requireAppAdmin } from '../guards/auth.js';

const gcpResolvers = {
  Query: {
    cloudRunServiceStatus: async (_parent: unknown, _args: unknown, context: Context) => {
      requireAppAdmin(context);
      return new GcpService(context.prisma).getCloudRunServiceStatus();
    },

    gcpMetrics: async (_parent: unknown, { period, metricName }: { period: string; metricName: string }, context: Context) => {
      requireAppAdmin(context);
      return new GcpService(context.prisma).getMetrics(period, metricName);
    },

    gcpLogs: async (_parent: unknown, { limit, filter }: { limit?: number; filter?: string }, context: Context) => {
      requireAppAdmin(context);
      return new GcpService(context.prisma).getLogs(limit, filter);
    },

    gcpCostBreakdown: async (_parent: unknown, { startDate, endDate }: { startDate: string; endDate: string }, context: Context) => {
      requireAppAdmin(context);
      return new GcpService(context.prisma).getCostBreakdown(startDate, endDate);
    },

    databaseStats: async (_parent: unknown, _args: unknown, context: Context) => {
      requireAppAdmin(context);
      return new GcpService(context.prisma).getDatabaseStats();
    },
  },
};

export default gcpResolvers;
