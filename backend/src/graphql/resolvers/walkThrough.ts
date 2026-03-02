/**
 * Walk-Through Completion Resolvers
 *
 * GraphQL resolvers for walk-through checklist persistence.
 *
 * Authorization:
 *   - submitWalkThroughCompletion: requireVolunteer + resolveAttendantVolunteer
 *   - walkThroughCompletions: requireAdmin + requireEventAccess
 *   - myWalkThroughCompletions: requireVolunteer + resolveAttendantVolunteer
 *
 * Used by: ./index.ts (resolver composition)
 */
import { Context } from '../context.js';
import { WalkThroughService } from '../../services/walkThroughService.js';
import { requireAdmin, requireAuth, requireEventAccess } from '../guards/auth.js';
import { SubmitWalkThroughCompletionInput } from '../validators/walkThrough.js';
import { AuthorizationError } from '../../utils/errors.js';

const walkThroughResolvers = {
  Query: {
    walkThroughCompletions: async (
      _parent: unknown,
      { eventId, sessionId }: { eventId: string; sessionId?: string },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);

      const service = new WalkThroughService(context.prisma);
      return service.getCompletions(eventId, sessionId);
    },

    myWalkThroughCompletions: async (
      _parent: unknown,
      _args: unknown,
      context: Context
    ) => {
      requireAuth(context);
      const eventVolunteer = await context.prisma.eventVolunteer.findFirst({
        where: { userId: context.user!.id },
        orderBy: { createdAt: 'desc' },
      });
      if (!eventVolunteer) throw new AuthorizationError('Volunteer not found');
      const eventVolunteerId = eventVolunteer.id;

      const service = new WalkThroughService(context.prisma);
      return service.getMyCompletions(eventVolunteerId);
    },
  },

  Mutation: {
    submitWalkThroughCompletion: async (
      _parent: unknown,
      { input }: { input: SubmitWalkThroughCompletionInput },
      context: Context
    ) => {
      requireAuth(context);
      const eventVolunteer = await context.prisma.eventVolunteer.findFirst({
        where: { userId: context.user!.id },
        orderBy: { createdAt: 'desc' },
      });
      if (!eventVolunteer) throw new AuthorizationError('Volunteer not found');
      const eventVolunteerId = eventVolunteer.id;

      const service = new WalkThroughService(context.prisma);
      return service.submitCompletion(eventVolunteerId, input);
    },
  },
};

export default walkThroughResolvers;
