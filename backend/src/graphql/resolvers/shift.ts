/**
 * Shift Resolvers
 *
 * GraphQL resolvers for shift operations.
 * Shifts subdivide sessions into custom time blocks for departments
 * that need finer scheduling granularity (e.g., 1-hour exterior attendant shifts).
 *
 * Queries:
 *   - shifts(sessionId): List all shifts for a session
 *
 * Mutations:
 *   - createShift(input): Create a shift within a session (overseer)
 *   - updateShift(id, input): Update shift details (overseer)
 *   - deleteShift(id): Remove a shift (overseer, cascades assignments)
 *
 * Field Resolvers:
 *   - session: Parent session
 *   - assignments: Assignments linked to this shift
 *
 * Authorization:
 *   Queries: requireAdmin + event access
 *   Mutations: requireAdmin + event access (via session's event)
 *
 * Used by: ./index.ts (resolver composition)
 */
import { Context } from '../context.js';
import { ShiftService } from '../../services/shiftService.js';
import { SessionService } from '../../services/sessionService.js';
import { requireAuth, requireEventAccess, tryRequireAdmin, tryRequireDeptAccessByEvent } from '../guards/auth.js';
import { Shift } from '@prisma/client';
import { CreateShiftInput, UpdateShiftInput } from '../validators/shift.js';

/**
 * Check overseer OR assistant overseer access via eventId.
 */
async function requireShiftMgmtAccess(context: Context, eventId: string) {
  if (tryRequireAdmin(context)) {
    await requireEventAccess(context, eventId);
    return;
  }
  const access = await tryRequireDeptAccessByEvent(context, eventId);
  if (!access) {
    throw new Error('Department overseer or assistant overseer access required');
  }
}

const shiftResolvers = {
  Query: {
    shifts: async (
      _parent: unknown,
      { sessionId, postId }: { sessionId: string; postId?: string },
      context: Context
    ) => {
      requireAuth(context);

      // Verify event access via session
      const sessionService = new SessionService(context.prisma);
      const eventId = await sessionService.getSessionEventId(sessionId);
      await requireShiftMgmtAccess(context, eventId);

      const shiftService = new ShiftService(context.prisma);
      return shiftService.getShifts(sessionId, postId ?? undefined);
    },
  },

  Mutation: {
    createShift: async (
      _parent: unknown,
      { input }: { input: CreateShiftInput },
      context: Context
    ) => {
      requireAuth(context);

      // Verify event access via session
      const sessionService = new SessionService(context.prisma);
      const eventId = await sessionService.getSessionEventId(input.sessionId);
      await requireShiftMgmtAccess(context, eventId);

      const shiftService = new ShiftService(context.prisma);
      return shiftService.createShift(input, context.user!.id);
    },

    updateShift: async (
      _parent: unknown,
      { id, input }: { id: string; input: UpdateShiftInput },
      context: Context
    ) => {
      requireAuth(context);

      // Verify event access via shift's session
      const shiftService = new ShiftService(context.prisma);
      const sessionId = await shiftService.getShiftSessionId(id);
      const sessionService = new SessionService(context.prisma);
      const eventId = await sessionService.getSessionEventId(sessionId);
      await requireShiftMgmtAccess(context, eventId);

      return shiftService.updateShift(id, input);
    },

    deleteShift: async (
      _parent: unknown,
      { id }: { id: string },
      context: Context
    ) => {
      requireAuth(context);

      // Verify event access via shift's session
      const shiftService = new ShiftService(context.prisma);
      const sessionId = await shiftService.getShiftSessionId(id);
      const sessionService = new SessionService(context.prisma);
      const eventId = await sessionService.getSessionEventId(sessionId);
      await requireShiftMgmtAccess(context, eventId);

      return shiftService.deleteShift(id);
    },
  },

  Shift: {
    session: (parent: Shift, _args: unknown, context: Context) => {
      return context.prisma.session.findUnique({
        where: { id: parent.sessionId },
      });
    },
    post: (parent: Shift, _args: unknown, context: Context) => {
      return context.prisma.post.findUnique({
        where: { id: parent.postId },
      });
    },
    assignments: (parent: Shift, _args: unknown, context: Context) => {
      return context.prisma.scheduleAssignment.findMany({
        where: { shiftId: parent.id },
        include: {
          post: true,
          session: true,
          eventVolunteer: { include: { user: true } },
          checkIn: true,
        },
      });
    },
    createdBy: (parent: Shift & { createdBy?: unknown }, _args: unknown, context: Context) => {
      if (parent.createdBy) return parent.createdBy;
      if (!parent.createdByUserId) return null;
      return context.prisma.user.findUnique({
        where: { id: parent.createdByUserId },
      });
    },
  },
};

export default shiftResolvers;
