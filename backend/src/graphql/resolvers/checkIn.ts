/**
 * Check-In Resolvers
 *
 * GraphQL resolvers for volunteer check-in/check-out and attendance tracking.
 *
 * Queries:
 *   - checkIn: Get check-in record by ID
 *   - sessionCheckIns: Get all check-ins for a session
 *   - checkInStats: Get check-in statistics for a session
 *   - attendanceCount: Get attendance count for a session
 *   - eventAttendanceCounts: Get all attendance counts for an event
 *
 * Mutations:
 *   - checkIn: Volunteer checks in to their assignment
 *   - checkOut: Volunteer checks out of their assignment
 *   - adminCheckIn: Admin checks in a volunteer on their behalf
 *   - markNoShow: Admin marks a volunteer as no-show
 *   - recordAttendance: Admin records attendance count for a session
 *   - updateAttendance: Admin updates an existing attendance record
 *   - deleteAttendance: Admin deletes an attendance record
 */
import { Context } from '../context.js';
import { CheckInService } from '../../services/checkInService.js';
import { AttendanceService } from '../../services/attendanceService.js';
import { requireAdmin, requireVolunteer, requireEventAccess } from '../guards/auth.js';
import {
  CheckInInput,
  CheckOutInput,
  AdminCheckInInput,
  MarkNoShowInput,
  RecordAttendanceInput,
  UpdateAttendanceInput,
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

    attendanceCount: async (
      _parent: unknown,
      { sessionId }: { sessionId: string },
      context: Context
    ) => {
      requireAdmin(context);

      const attendanceService = new AttendanceService(context.prisma);
      const eventId = await attendanceService.getSessionEventId(sessionId);
      await requireEventAccess(context, eventId);

      return attendanceService.getAttendance(sessionId);
    },

    eventAttendanceCounts: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);

      const attendanceService = new AttendanceService(context.prisma);
      return attendanceService.getEventAttendance(eventId);
    },
  },

  Mutation: {
    checkIn: async (_parent: unknown, { input }: { input: CheckInInput }, context: Context) => {
      requireVolunteer(context);

      const checkInService = new CheckInService(context.prisma);
      return checkInService.checkIn(context.volunteer.id, input);
    },

    checkOut: async (_parent: unknown, { input }: { input: CheckOutInput }, context: Context) => {
      requireVolunteer(context);

      const checkInService = new CheckInService(context.prisma);
      return checkInService.checkOut(context.volunteer.id, input);
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

      return checkInService.adminCheckIn(context.admin.id, input);
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

      return checkInService.markNoShow(context.admin.id, input);
    },

    recordAttendance: async (
      _parent: unknown,
      { input }: { input: RecordAttendanceInput },
      context: Context
    ) => {
      requireAdmin(context);

      const attendanceService = new AttendanceService(context.prisma);
      const eventId = await attendanceService.getSessionEventId(input.sessionId);
      await requireEventAccess(context, eventId, ['EVENT_OVERSEER']);

      return attendanceService.recordAttendance(context.admin.id, input);
    },

    updateAttendance: async (
      _parent: unknown,
      { id, input }: { id: string; input: UpdateAttendanceInput },
      context: Context
    ) => {
      requireAdmin(context);

      const attendance = await context.prisma.attendanceCount.findUnique({
        where: { id },
        include: { session: { select: { eventId: true } } },
      });

      if (attendance) {
        await requireEventAccess(context, attendance.session.eventId, ['EVENT_OVERSEER']);
      }

      const attendanceService = new AttendanceService(context.prisma);
      return attendanceService.updateAttendance(id, input);
    },

    deleteAttendance: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAdmin(context);

      const attendance = await context.prisma.attendanceCount.findUnique({
        where: { id },
        include: { session: { select: { eventId: true } } },
      });

      if (attendance) {
        await requireEventAccess(context, attendance.session.eventId, ['EVENT_OVERSEER']);
      }

      const attendanceService = new AttendanceService(context.prisma);
      return attendanceService.deleteAttendance(id);
    },
  },
};

export default checkInResolvers;
