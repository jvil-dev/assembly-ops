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
import { requireAuth, requireVolunteer } from '../guards/auth.js';
import { UpdatePostSessionStatusInput } from '../validators/postSessionStatus.js';
import { AuthorizationError } from '../../utils/errors.js';

/**
 * Resolve EventVolunteer for authenticated volunteer (dual-auth bridge).
 */
async function resolveEventVolunteer(
  context: Context
): Promise<string> {
  const ev = await context.prisma.eventVolunteer.findUnique({
    where: { id: context.volunteer!.id },
  });
  if (ev) return ev.id;

  const volunteer = await context.prisma.volunteer.findUnique({
    where: { id: context.volunteer!.id },
  });
  if (!volunteer) {
    throw new AuthorizationError('Volunteer not found');
  }

  const eventVolunteer = await context.prisma.eventVolunteer.findFirst({
    where: { volunteerId: volunteer.volunteerId },
  });
  if (!eventVolunteer) {
    throw new AuthorizationError('Event volunteer not found');
  }

  return eventVolunteer.id;
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
      requireVolunteer(context);
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
