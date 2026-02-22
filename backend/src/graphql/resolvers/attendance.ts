/**
 * Attendance Resolvers
 *
 * GraphQL resolvers for audience attendance count operations.
 * Used for CO-24 reporting with section-based counting.
 *
 * Authorization:
 *   - All operations require Admin auth + event access
 *   - Typically used by Attendant department overseers
 *
 * Query Resolvers:
 *   - attendanceCount(id): Get single count by ID
 *   - sessionAttendanceCounts(sessionId): All counts for a session
 *   - sessionTotalAttendance(sessionId): Sum of all section counts
 *   - eventAttendanceSummary(eventId): Aggregated counts per session
 *
 * Mutation Resolvers:
 *   - submitAttendanceCount: Record count for session/section (upserts)
 *   - updateAttendanceCount: Modify existing count
 *   - deleteAttendanceCount: Remove count record
 *
 * Type Resolvers:
 *   - AttendanceCount.session: Resolve related session
 *   - AttendanceCount.submittedBy: Resolve admin who submitted
 *
 * Used by: ./index.ts (resolver composition)
 */
import { AttendanceCount } from '@prisma/client';
import { Context } from '../context.js';
import { AttendanceService } from '../../services/attendanceService.js';
import { requireAdmin, requireAuth, requireEventAccess } from '../guards/auth.js';
import { AuthorizationError } from '../../utils/errors.js';
import {
  SubmitAttendanceCountInput,
  UpdateAttendanceCountInput,
} from '../validators/attendance.js';

const attendanceResolvers = {
  Query: {
    attendanceCount: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAdmin(context);
      const attendanceService = new AttendanceService(context.prisma);
      return attendanceService.getAttendanceCount(id);
    },

    sessionAttendanceCounts: async (
      _parent: unknown,
      { sessionId }: { sessionId: string },
      context: Context
    ) => {
      requireAdmin(context);
      const attendanceService = new AttendanceService(context.prisma);
      const eventId = await attendanceService.getSessionEventId(sessionId);
      await requireEventAccess(context, eventId);

      return attendanceService.getSessionAttendanceCounts(sessionId);
    },

    sessionTotalAttendance: async (
      _parent: unknown,
      { sessionId }: { sessionId: string },
      context: Context
    ) => {
      requireAdmin(context);
      const attendanceService = new AttendanceService(context.prisma);
      const eventId = await attendanceService.getSessionEventId(sessionId);
      await requireEventAccess(context, eventId);

      return attendanceService.getSessionTotalAttendance(sessionId);
    },

    eventAttendanceCounts: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);

      const attendanceService = new AttendanceService(context.prisma);
      return attendanceService.getEventAttendanceCounts(eventId);
    },

    eventAttendanceSummary: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);

      const attendanceService = new AttendanceService(context.prisma);
      return attendanceService.getEventAttendanceSummary(eventId);
    },

    volunteerSessionsForEvent: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAuth(context);
      return context.prisma.session.findMany({
        where: { eventId },
        orderBy: [{ date: 'asc' }, { startTime: 'asc' }],
      });
    },
  },

  Mutation: {
    submitAttendanceCount: async (
      _parent: unknown,
      { input }: { input: SubmitAttendanceCountInput },
      context: Context
    ) => {
      requireAuth(context);
      const attendanceService = new AttendanceService(context.prisma);

      // Volunteer path: attendant-only, section-scoped
      if (context.volunteer) {
        const eventId = await attendanceService.getSessionEventId(input.sessionId);

        const eventVolunteer = await context.prisma.eventVolunteer.findFirst({
          where: {
            volunteerProfileId: context.volunteer.id,
            eventId,
          },
          include: { department: true },
        });

        if (!eventVolunteer || eventVolunteer.department?.departmentType !== 'ATTENDANT') {
          throw new AuthorizationError('Only attendant volunteers can submit counts');
        }

        return attendanceService.submitVolunteerAttendanceCount(eventVolunteer.id, input);
      }

      // Admin path: existing behavior
      requireAdmin(context);
      const eventId = await attendanceService.getSessionEventId(input.sessionId);
      await requireEventAccess(context, eventId);

      return attendanceService.submitAttendanceCount(context.admin.id, input);
    },

    updateAttendanceCount: async (
      _parent: unknown,
      { id, input }: { id: string; input: UpdateAttendanceCountInput },
      context: Context
    ) => {
      requireAdmin(context);
      const attendanceService = new AttendanceService(context.prisma);
      const eventId = await attendanceService.getAttendanceCountEventId(id);
      await requireEventAccess(context, eventId);

      return attendanceService.updateAttendanceCount(id, input);
    },

    deleteAttendanceCount: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAdmin(context);
      const attendanceService = new AttendanceService(context.prisma);
      const eventId = await attendanceService.getAttendanceCountEventId(id);
      await requireEventAccess(context, eventId);

      return attendanceService.deleteAttendanceCount(id);
    },
  },

  AttendanceCount: {
    session: async (
      parent: AttendanceCount & { session?: unknown },
      _args: unknown,
      context: Context
    ) => {
      if (parent.session) return parent.session;
      return context.prisma.session.findUnique({
        where: { id: parent.sessionId },
      });
    },

    submittedBy: async (
      parent: AttendanceCount & { submittedBy?: unknown },
      _args: unknown,
      context: Context
    ) => {
      if (parent.submittedBy) return parent.submittedBy;
      return context.prisma.admin.findUnique({
        where: { id: parent.submittedById },
      });
    },
  },
};

export default attendanceResolvers;
