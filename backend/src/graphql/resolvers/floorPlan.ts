import { Context } from '../context.js';
import { FloorPlanService } from '../../services/floorPlanService.js';
import { requireAuth, requireAdmin, requireEventAccess } from '../guards/auth.js';

const floorPlanResolvers = {
  Query: {
    floorPlanUrl: async (_: unknown, { eventId }: { eventId: string }, context: Context) => {
      requireAuth(context);
      const svc = new FloorPlanService(context.prisma);
      return svc.getViewUrl(eventId);
    },
  },
  Mutation: {
    getFloorPlanUploadUrl: async (_: unknown, { eventId }: { eventId: string }, context: Context) => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);
      const svc = new FloorPlanService(context.prisma);
      return svc.getUploadUrl(eventId);
    },
    confirmFloorPlanUpload: async (_: unknown, { eventId }: { eventId: string }, context: Context) => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);
      const svc = new FloorPlanService(context.prisma);
      await svc.confirmUpload(eventId);
      return true;
    },
    deleteFloorPlan: async (_: unknown, { eventId }: { eventId: string }, context: Context) => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);
      const svc = new FloorPlanService(context.prisma);
      await svc.delete(eventId);
      return true;
    },
  },
};

export default floorPlanResolvers;
