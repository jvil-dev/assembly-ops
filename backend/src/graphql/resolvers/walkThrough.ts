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
import { requireAdmin, requireVolunteer, requireEventAccess } from '../guards/auth.js';
import { SubmitWalkThroughCompletionInput } from '../validators/walkThrough.js';
import { AuthorizationError } from '../../utils/errors.js';

/**
 * Resolve EventVolunteer for authenticated volunteer (dual-auth bridge).
 * Same pattern as attendant.ts resolveAttendantVolunteer but without department check.
 */
async function resolveEventVolunteer(
  context: Context
): Promise<string> {
  const ev = await context.prisma.eventVolunteer.findUnique({
    where: { id: context.volunteer!.id },
  });
  if (!ev) {
    throw new AuthorizationError('Volunteer not found');
  }
  return ev.id;
}

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
      requireVolunteer(context);
      const eventVolunteerId = await resolveEventVolunteer(context);

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
      requireVolunteer(context);
      const eventVolunteerId = await resolveEventVolunteer(context);

      const service = new WalkThroughService(context.prisma);
      return service.submitCompletion(eventVolunteerId, input);
    },
  },
};

export default walkThroughResolvers;
