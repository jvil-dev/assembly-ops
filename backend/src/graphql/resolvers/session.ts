/**
 * Session Resolvers
 *
 * GraphQL resolvers for session operations.
 * Sessions are event-wide time blocks (e.g., "Friday Morning", "Saturday Afternoon").
 * All departments share the same sessions within an event.
 *
 * Queries:
 *   - session(id): Get single session by ID
 *   - sessions(eventId): List all sessions for an event
 *
 * Mutations:
 *   - createSession(eventId, input): Create single session (overseer)
 *   - createSessions(input): Bulk create sessions (overseer)
 *   - updateSession(id, input): Update session details (overseer)
 *   - deleteSession(id): Remove a session (overseer)
 *
 * Field Resolvers:
 *   - startTime/endTime: Return time as-is for DateTime scalar
 *   - assignmentCount: Number of assignments in this session
 *
 * Authorization:
 *   All operations require admin authentication.
 *   Mutations restricted to overseer role.
 */
import { Context } from '../context.js';
import { SessionService } from '../../services/sessionService.js';
import { requireAuth, requireEventAccess, tryRequireAdmin, tryRequireDeptAccessByEvent, requireDeptAccess } from '../guards/auth.js';
import { AuthorizationError } from '../../utils/errors.js';
import { Session } from '@prisma/client';
import {
  CreateSessionInput,
  CreateSessionsInput,
  UpdateSessionInput,
} from '../validators/session.js';

/**
 * Check admin OR assistant overseer access for an event.
 * Tries requireAdmin + requireEventAccess first, falls back to tryRequireDeptAccessByEvent.
 */
async function requireSessionAccess(context: Context, eventId: string) {
  requireAuth(context);
  if (tryRequireAdmin(context)) {
    await requireEventAccess(context, eventId);
  } else {
    const access = await tryRequireDeptAccessByEvent(context, eventId);
    if (!access) throw new AuthorizationError('Department access required');
  }
}

const sessionResolvers = {
  Query: {
    session: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      const sessionService = new SessionService(context.prisma);
      const eventId = await sessionService.getSessionEventId(id);
      await requireSessionAccess(context, eventId);

      return sessionService.getSession(id);
    },

    sessions: async (_parent: unknown, { eventId, departmentId }: { eventId: string; departmentId?: string }, context: Context) => {
      await requireSessionAccess(context, eventId);

      const sessionService = new SessionService(context.prisma);
      return sessionService.getEventSessions(eventId, departmentId);
    },
  },

  Mutation: {
    createSession: async (
      _parent: unknown,
      { eventId, input }: { eventId: string; input: CreateSessionInput },
      context: Context
    ) => {
      await requireSessionAccess(context, eventId);

      const sessionService = new SessionService(context.prisma);
      return sessionService.createSession(eventId, input);
    },

    createSessions: async (
      _parent: unknown,
      { input }: { input: CreateSessionsInput },
      context: Context
    ) => {
      await requireSessionAccess(context, input.eventId);

      const sessionService = new SessionService(context.prisma);
      return sessionService.createSessions(input);
    },

    updateSession: async (
      _parent: unknown,
      { id, input }: { id: string; input: UpdateSessionInput },
      context: Context
    ) => {
      const sessionService = new SessionService(context.prisma);
      const eventId = await sessionService.getSessionEventId(id);
      await requireSessionAccess(context, eventId);

      return sessionService.updateSession(id, input);
    },

    deleteSession: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      const sessionService = new SessionService(context.prisma);
      const eventId = await sessionService.getSessionEventId(id);
      await requireSessionAccess(context, eventId);

      return sessionService.deleteSession(id);
    },

    upsertDepartmentSession: async (
      _parent: unknown,
      args: { departmentId: string; sessionId: string; input: { startTime?: string; endTime?: string; notes?: string } },
      context: Context
    ) => {
      await requireDeptAccess(context, args.departmentId);

      const sessionService = new SessionService(context.prisma);
      return sessionService.upsertDepartmentSession(args.departmentId, args.sessionId, args.input);
    },
  },

  Session: {
    // Format time fields for GraphQL response
    startTime: (session: Session) => {
      // Return as ISO string for DateTime scalar
      return session.startTime;
    },
    endTime: (session: Session) => {
      return session.endTime;
    },
    assignmentCount: (session: Session & { _count?: { assignments: number } }) => {
      return session._count?.assignments ?? 0;
    },
    shifts: async (session: Session, _args: unknown, context: Context) => {
      return context.prisma.shift.findMany({
        where: { sessionId: session.id },
        orderBy: { startTime: 'asc' },
      });
    },
    departmentSession: async (session: Session, args: { departmentId?: string }, context: Context) => {
      let deptId = args.departmentId;

      // If no departmentId provided, auto-resolve from the authenticated user's event volunteer
      if (!deptId && context.user) {
        const ev = await context.prisma.eventVolunteer.findFirst({
          where: { userId: context.user.id, eventId: session.eventId },
          select: { departmentId: true },
        });
        deptId = ev?.departmentId ?? undefined;
      }

      if (!deptId) return null;
      const sessionService = new SessionService(context.prisma);
      return sessionService.getDepartmentSession(deptId, session.id);
    },
  },
};

export default sessionResolvers;
