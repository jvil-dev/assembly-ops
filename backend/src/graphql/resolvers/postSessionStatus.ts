/**
 * Post Session Status Resolvers
 *
 * GraphQL resolvers for seating section status management.
 *
 * Authorization:
 *   - updatePostSessionStatus: requireVolunteer (must be assigned to post)
 *   - postSessionStatuses: requireAuth (any attendant/admin)
 *   - eventPostSessionStatuses: requireAuth
 *
 * Used by: ./index.ts (resolver composition)
 */
import { Context } from '../context.js';
import { PostSessionStatusService } from '../../services/postSessionStatusService.js';
import { requireAuth } from '../guards/auth.js';
import { UpdatePostSessionStatusInput } from '../validators/postSessionStatus.js';
import { AuthorizationError } from '../../utils/errors.js';

/**
 * Resolve EventVolunteer for authenticated user.
 */
async function resolveEventVolunteer(
  context: Context
): Promise<string> {
  if (!context.user) throw new AuthorizationError('You must be logged in');
  const ev = await context.prisma.eventVolunteer.findFirst({
    where: { userId: context.user.id },
    orderBy: { createdAt: 'desc' },
  });
  if (!ev) throw new AuthorizationError('Event volunteer not found');
  return ev.id;
}

const postSessionStatusResolvers = {
  Query: {
    postSessionStatuses: async (
      _parent: unknown,
      { sessionId }: { sessionId: string },
      context: Context
    ) => {
      requireAuth(context);

      const service = new PostSessionStatusService(context.prisma);
      return service.getStatusesForSession(sessionId);
    },

    eventPostSessionStatuses: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAuth(context);

      const service = new PostSessionStatusService(context.prisma);
      return service.getStatusesForEvent(eventId);
    },
  },

  Mutation: {
    updatePostSessionStatus: async (
      _parent: unknown,
      { input }: { input: UpdatePostSessionStatusInput },
      context: Context
    ) => {
      requireAuth(context);
      const eventVolunteerId = await resolveEventVolunteer(context);

      // Verify volunteer is assigned to this post in this session
      const assignment = await context.prisma.scheduleAssignment.findFirst({
        where: {
          eventVolunteerId,
          postId: input.postId,
          sessionId: input.sessionId,
          status: 'ACCEPTED',
        },
      });

      if (!assignment) {
        throw new AuthorizationError('You must be assigned to this post to update its status');
      }

      const service = new PostSessionStatusService(context.prisma);
      return service.updateStatus(eventVolunteerId, input);
    },
  },
};

export default postSessionStatusResolvers;
