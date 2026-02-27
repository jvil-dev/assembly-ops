/**
 * Admin Resolvers
 *
 * Handles app-admin operations: CSV imports and analytics.
 * All operations require isAppAdmin via requireAppAdmin guard.
 *
 * Schema: ../schema/admin.ts
 */
import { Context } from '../context.js';
import { AdminService } from '../../services/adminService.js';
import { requireAppAdmin } from '../guards/auth.js';

const adminResolvers = {
  Query: {
    appAnalytics: async (_parent: unknown, _args: unknown, context: Context) => {
      requireAppAdmin(context);
      const adminService = new AdminService(context.prisma);
      return adminService.getAppAnalytics();
    },

    userGrowth: async (_parent: unknown, { period }: { period: string }, context: Context) => {
      requireAppAdmin(context);
      const adminService = new AdminService(context.prisma);
      return adminService.getUserGrowth(period);
    },

    eventStats: async (_parent: unknown, _args: unknown, context: Context) => {
      requireAppAdmin(context);
      const adminService = new AdminService(context.prisma);
      return adminService.getEventStats();
    },
  },

  Mutation: {
    importCongregations: async (_parent: unknown, { csvData }: { csvData: string }, context: Context) => {
      requireAppAdmin(context);
      const adminService = new AdminService(context.prisma);
      return adminService.importCongregations(csvData);
    },

    importEvents: async (_parent: unknown, { csvData }: { csvData: string }, context: Context) => {
      requireAppAdmin(context);
      const adminService = new AdminService(context.prisma);
      return adminService.importEvents(csvData);
    },

    importVolunteers: async (_parent: unknown, { eventId, csvData }: { eventId: string; csvData: string }, context: Context) => {
      requireAppAdmin(context);
      const adminService = new AdminService(context.prisma);
      return adminService.importVolunteers(eventId, csvData);
    },
  },
};

export default adminResolvers;
