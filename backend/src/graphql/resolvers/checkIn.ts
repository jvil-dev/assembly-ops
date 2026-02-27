/**
 * Check-In Resolvers
 *
 * GraphQL resolvers for volunteer check-in/check-out operations.
 * Attendance tracking has been moved to attendance.ts.
 *
 * Queries:
 *   - checkIn: Get check-in record by ID
 *   - sessionCheckIns: Get all check-ins for a session
 *   - checkInStats: Get check-in statistics for a session
 *
 * Mutations:
 *   - checkIn: Volunteer checks in to their assignment
 *   - checkOut: Volunteer checks out of their assignment
 *   - adminCheckIn: Overseer checks in a volunteer on their behalf
 *   - markNoShow: Overseer marks a volunteer as no-show
 */
import { Context } from '../context.js';
import { CheckInService } from '../../services/checkInService.js';
import { requireAdmin, requireAuth, requireEventAccess, resolveUserEventVolunteer } from '../guards/auth.js';
import {
  CheckInInput,
  CheckOutInput,
  AdminCheckInInput,
  MarkNoShowInput,
} from '../validators/checkIn.js';

const checkInResolvers = {
  Query: {
    checkIn: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAdmin(context);
      const checkInService = new CheckInService(context.prisma);
      return checkInService.getCheckIn(id);
    },

    sessionCheckIns: async (
      _parent: unknown,
      { sessionId }: { sessionId: string },
      context: Context
    ) => {
      requireAdmin(context);

      // Get session's eventId for access check
      const session = await context.prisma.session.findUnique({
        where: { id: sessionId },
        select: { eventId: true },
      });

      if (session) {
        await requireEventAccess(context, session.eventId);
      }

      const checkInService = new CheckInService(context.prisma);
      return checkInService.getSessionCheckIns(sessionId);
    },

    checkInStats: async (
      _parent: unknown,
      { sessionId }: { sessionId: string },
      context: Context
    ) => {
      requireAdmin(context);

      // Get session's eventId for access check
      const session = await context.prisma.session.findUnique({
        where: { id: sessionId },
        select: { eventId: true },
      });

      if (session) {
        await requireEventAccess(context, session.eventId);
      }

      const checkInService = new CheckInService(context.prisma);
      return checkInService.getCheckInStats(sessionId);
    },
  },

  Mutation: {
    checkIn: async (_parent: unknown, { input }: { input: CheckInInput }, context: Context) => {
      requireAuth(context);
      const assignment = await context.prisma.scheduleAssignment.findUnique({
        where: { id: input.assignmentId },
        include: { session: { select: { eventId: true } } },
      });
      if (!assignment) throw new Error('Assignment not found');
      const ev = await resolveUserEventVolunteer(context.user!.id, assignment.session.eventId, context.prisma);

      const checkInService = new CheckInService(context.prisma);
      return checkInService.checkIn(ev.id, input);
    },

    checkOut: async (_parent: unknown, { input }: { input: CheckOutInput }, context: Context) => {
      requireAuth(context);
      const assignment = await context.prisma.scheduleAssignment.findUnique({
        where: { id: input.assignmentId },
        include: { session: { select: { eventId: true } } },
      });
      if (!assignment) throw new Error('Assignment not found');
      const ev = await resolveUserEventVolunteer(context.user!.id, assignment.session.eventId, context.prisma);

      const checkInService = new CheckInService(context.prisma);
      return checkInService.checkOut(ev.id, input);
    },

    adminCheckIn: async (
      _parent: unknown,
      { input }: { input: AdminCheckInInput },
      context: Context
    ) => {
      requireAdmin(context);

      const checkInService = new CheckInService(context.prisma);
      const eventId = await checkInService.getAssignmentEventId(input.assignmentId);
      await requireEventAccess(context, eventId);

      return checkInService.adminCheckIn(context.user!.id, input);
    },

    markNoShow: async (
      _parent: unknown,
      { input }: { input: MarkNoShowInput },
      context: Context
    ) => {
      requireAdmin(context);

      const checkInService = new CheckInService(context.prisma);
      const eventId = await checkInService.getAssignmentEventId(input.assignmentId);
      await requireEventAccess(context, eventId);

      return checkInService.markNoShow(context.user!.id, input);
    },
  },
};

export default checkInResolvers;
