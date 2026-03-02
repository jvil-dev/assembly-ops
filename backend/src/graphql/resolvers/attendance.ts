/**
 * Attendance Resolvers
 *
 * GraphQL resolvers for audience attendance count operations.
 * Used for CO-24 reporting with section-based counting.
 *
 * Authorization:
 *   - All operations require Overseer auth + event access
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
 *   - AttendanceCount.submittedBy: Resolve overseer who submitted
 *
 * Used by: ./index.ts (resolver composition)
 */
import { AttendanceCount } from '@prisma/client';
import { Context } from '../context.js';
import { AttendanceService } from '../../services/attendanceService.js';
import { requireAuth, requireEventAccess, tryRequireAdmin, tryRequireDeptAccessByEvent, requireCaptain } from '../guards/auth.js';
import { AuthorizationError } from '../../utils/errors.js';
import {
  SubmitAttendanceCountInput,
  UpdateAttendanceCountInput,
} from '../validators/attendance.js';

const attendanceResolvers = {
  Query: {
    attendanceCount: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAuth(context);
      const attendanceService = new AttendanceService(context.prisma);
      const eventId = await attendanceService.getAttendanceCountEventId(id);
      if (tryRequireAdmin(context)) {
        await requireEventAccess(context, eventId);
      } else {
        const access = await tryRequireDeptAccessByEvent(context, eventId);
        if (!access) throw new AuthorizationError('Department access required');
      }
      return attendanceService.getAttendanceCount(id);
    },

    sessionAttendanceCounts: async (
      _parent: unknown,
      { sessionId }: { sessionId: string },
      context: Context
    ) => {
      requireAuth(context);
      const attendanceService = new AttendanceService(context.prisma);
      const eventId = await attendanceService.getSessionEventId(sessionId);
      if (tryRequireAdmin(context)) {
        await requireEventAccess(context, eventId);
      } else {
        const access = await tryRequireDeptAccessByEvent(context, eventId);
        if (!access) throw new AuthorizationError('Department access required');
      }

      return attendanceService.getSessionAttendanceCounts(sessionId);
    },

    sessionTotalAttendance: async (
      _parent: unknown,
      { sessionId }: { sessionId: string },
      context: Context
    ) => {
      requireAuth(context);
      const attendanceService = new AttendanceService(context.prisma);
      const eventId = await attendanceService.getSessionEventId(sessionId);
      if (tryRequireAdmin(context)) {
        await requireEventAccess(context, eventId);
      } else {
        const access = await tryRequireDeptAccessByEvent(context, eventId);
        if (!access) throw new AuthorizationError('Department access required');
      }

      return attendanceService.getSessionTotalAttendance(sessionId);
    },

    eventAttendanceCounts: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAuth(context);
      if (tryRequireAdmin(context)) {
        await requireEventAccess(context, eventId);
      } else {
        const access = await tryRequireDeptAccessByEvent(context, eventId);
        if (!access) throw new AuthorizationError('Department access required');
      }

      const attendanceService = new AttendanceService(context.prisma);
      return attendanceService.getEventAttendanceCounts(eventId);
    },

    eventAttendanceSummary: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAuth(context);
      if (tryRequireAdmin(context)) {
        await requireEventAccess(context, eventId);
      } else {
        const access = await tryRequireDeptAccessByEvent(context, eventId);
        if (!access) throw new AuthorizationError('Department access required');
      }

      const attendanceService = new AttendanceService(context.prisma);
      return attendanceService.getEventAttendanceSummary(eventId);
    },

    volunteerSessionsForEvent: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAuth(context);
      // Check if user has admin access or is a volunteer for this event
      const eventAdmin = await context.prisma.eventAdmin.findUnique({
        where: { userId_eventId: { userId: context.user!.id, eventId } },
      });
      if (!eventAdmin) {
        // Not an admin — check if they're a volunteer for this event
        const ev = await context.prisma.eventVolunteer.findUnique({
          where: { userId_eventId: { userId: context.user!.id, eventId } },
        });
        if (!ev) {
          throw new AuthorizationError('You do not have access to this event');
        }
      }
      return context.prisma.session.findMany({
        where: { eventId },
        orderBy: [{ date: 'asc' }, { startTime: 'asc' }],
      });
    },

    postAttendanceCounts: async (
      _parent: unknown,
      { postId }: { postId: string },
      context: Context
    ) => {
      requireAuth(context);
      const post = await context.prisma.post.findUnique({
        where: { id: postId },
        select: { department: { select: { eventId: true } } },
      });
      if (!post) {
        throw new AuthorizationError('Post not found');
      }
      const eventId = post.department.eventId;
      // Check if user has admin access or is a volunteer for this event
      const eventAdmin = await context.prisma.eventAdmin.findUnique({
        where: { userId_eventId: { userId: context.user!.id, eventId } },
      });
      if (!eventAdmin) {
        const ev = await context.prisma.eventVolunteer.findUnique({
          where: { userId_eventId: { userId: context.user!.id, eventId } },
        });
        if (!ev) {
          throw new AuthorizationError('You do not have access to this event');
        }
      }
      return context.prisma.attendanceCount.findMany({
        where: { postId },
        include: { session: true },
        orderBy: { updatedAt: 'desc' },
      });
    },

    captainAreaAttendanceCounts: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      const { eventVolunteerId } = await requireCaptain(context, eventId);

      // Find captain's areas (ACCEPTED area captain assignments)
      const areaCaptains = await context.prisma.areaCaptain.findMany({
        where: { eventVolunteerId, status: 'ACCEPTED' },
        select: { areaId: true },
      });

      if (areaCaptains.length === 0) return [];

      const areaIds = areaCaptains.map((ac) => ac.areaId);

      // Find all posts in those areas
      const posts = await context.prisma.post.findMany({
        where: { areaId: { in: areaIds } },
        select: { id: true },
      });

      if (posts.length === 0) return [];

      const postIds = posts.map((p) => p.id);

      // Get all attendance counts for those posts
      const counts = await context.prisma.attendanceCount.findMany({
        where: { postId: { in: postIds } },
        include: {
          post: {
            include: { area: true },
          },
          session: true,
          submittedBy: true,
        },
        orderBy: [{ session: { date: 'asc' } }, { session: { startTime: 'asc' } }, { post: { name: 'asc' } }],
      });

      return counts.map((c) => ({
        post: c.post,
        session: c.session,
        count: c.count,
        section: c.section,
        notes: c.notes,
        submittedBy: c.submittedBy,
        submittedAt: c.updatedAt,
      }));
    },

    myAttendanceStatus: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAuth(context);

      // Get user's EventVolunteer for this event
      const eventVolunteer = await context.prisma.eventVolunteer.findUnique({
        where: { userId_eventId: { userId: context.user!.id, eventId } },
        include: { department: true },
      });

      if (!eventVolunteer || eventVolunteer.department?.departmentType !== 'ATTENDANT') {
        return [];
      }

      // Get today's sessions
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      const todaySessions = await context.prisma.session.findMany({
        where: {
          eventId,
          date: { gte: today, lt: tomorrow },
        },
        orderBy: { startTime: 'asc' },
      });

      if (todaySessions.length === 0) return [];

      // Get user's ACCEPTED assignments for today's sessions
      const sessionIds = todaySessions.map((s) => s.id);
      const assignments = await context.prisma.scheduleAssignment.findMany({
        where: {
          eventVolunteerId: eventVolunteer.id,
          sessionId: { in: sessionIds },
          status: 'ACCEPTED',
        },
        include: { post: true },
      });

      // Check existing AttendanceCount records for those post+session combos
      const results = [];
      for (const session of todaySessions) {
        const sessionAssignments = assignments.filter((a) => a.sessionId === session.id);
        if (sessionAssignments.length === 0) continue;

        for (const assignment of sessionAssignments) {
          const existingCount = await context.prisma.attendanceCount.findFirst({
            where: {
              sessionId: session.id,
              postId: assignment.postId,
            },
          });

          results.push({
            session,
            hasSubmitted: !!existingCount,
            postId: assignment.postId,
            postName: assignment.post?.name ?? null,
          });
        }
      }

      return results;
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
      const eventId = await attendanceService.getSessionEventId(input.sessionId);

      // Check if user is an event admin
      const eventAdmin = await context.prisma.eventAdmin.findUnique({
        where: { userId_eventId: { userId: context.user!.id, eventId } },
      });

      if (eventAdmin) {
        // Admin path
        return attendanceService.submitAttendanceCount(context.user!.id, input);
      }

      // Volunteer path: must be attendant department member
      const eventVolunteer = await context.prisma.eventVolunteer.findUnique({
        where: { userId_eventId: { userId: context.user!.id, eventId } },
        include: { department: true },
      });

      if (!eventVolunteer || eventVolunteer.department?.departmentType !== 'ATTENDANT') {
        throw new AuthorizationError('Only attendant volunteers can submit counts');
      }

      return attendanceService.submitVolunteerAttendanceCount(eventVolunteer.id, input);
    },

    updateAttendanceCount: async (
      _parent: unknown,
      { id, input }: { id: string; input: UpdateAttendanceCountInput },
      context: Context
    ) => {
      requireAuth(context);
      const attendanceService = new AttendanceService(context.prisma);
      const eventId = await attendanceService.getAttendanceCountEventId(id);
      if (tryRequireAdmin(context)) {
        await requireEventAccess(context, eventId);
      } else {
        const access = await tryRequireDeptAccessByEvent(context, eventId);
        if (!access) throw new AuthorizationError('Department access required');
      }

      return attendanceService.updateAttendanceCount(id, input);
    },

    deleteAttendanceCount: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAuth(context);
      const attendanceService = new AttendanceService(context.prisma);
      const eventId = await attendanceService.getAttendanceCountEventId(id);
      if (tryRequireAdmin(context)) {
        await requireEventAccess(context, eventId);
      } else {
        const access = await tryRequireDeptAccessByEvent(context, eventId);
        if (!access) throw new AuthorizationError('Department access required');
      }

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
      return context.prisma.user.findUnique({
        where: { id: parent.submittedById },
      });
    },
  },
};

export default attendanceResolvers;
