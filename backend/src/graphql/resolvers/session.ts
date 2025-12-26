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
 *   - createSession(eventId, input): Create single session (EVENT_OVERSEER only)
 *   - createSessions(input): Bulk create sessions (EVENT_OVERSEER only)
 *   - updateSession(id, input): Update session details (EVENT_OVERSEER only)
 *   - deleteSession(id): Remove a session (EVENT_OVERSEER only)
 *
 * Field Resolvers:
 *   - startTime/endTime: Return time as-is for DateTime scalar
 *   - assignmentCount: Number of assignments in this session
 *
 * Authorization:
 *   All operations require admin authentication.
 *   Mutations restricted to EVENT_OVERSEER role.
 */
import { Context } from '../context.js';
import { SessionService } from '../../services/sessionService.js';
import { requireAdmin, requireEventAccess } from '../guards/auth.js';
import { Session } from '@prisma/client';
import {
  CreateSessionInput,
  CreateSessionsInput,
  UpdateSessionInput,
} from '../validators/session.js';

const sessionResolvers = {
  Query: {
    session: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAdmin(context);

      const sessionService = new SessionService(context.prisma);
      const eventId = await sessionService.getSessionEventId(id);
      await requireEventAccess(context, eventId);

      return sessionService.getSession(id);
    },

    sessions: async (_parent: unknown, { eventId }: { eventId: string }, context: Context) => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);

      const sessionService = new SessionService(context.prisma);
      return sessionService.getEventSessions(eventId);
    },
  },

  Mutation: {
    createSession: async (
      _parent: unknown,
      { eventId, input }: { eventId: string; input: CreateSessionInput },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, eventId, ['EVENT_OVERSEER']);

      const sessionService = new SessionService(context.prisma);
      return sessionService.createSession(eventId, input);
    },

    createSessions: async (
      _parent: unknown,
      { input }: { input: CreateSessionsInput },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, input.eventId, ['EVENT_OVERSEER']);

      const sessionService = new SessionService(context.prisma);
      return sessionService.createSessions(input);
    },

    updateSession: async (
      _parent: unknown,
      { id, input }: { id: string; input: UpdateSessionInput },
      context: Context
    ) => {
      requireAdmin(context);

      const sessionService = new SessionService(context.prisma);
      const eventId = await sessionService.getSessionEventId(id);
      await requireEventAccess(context, eventId, ['EVENT_OVERSEER']);

      return sessionService.updateSession(id, input);
    },

    deleteSession: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAdmin(context);

      const sessionService = new SessionService(context.prisma);
      const eventId = await sessionService.getSessionEventId(id);
      await requireEventAccess(context, eventId, ['EVENT_OVERSEER']);

      return sessionService.deleteSession(id);
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
  },
};

export default sessionResolvers;
