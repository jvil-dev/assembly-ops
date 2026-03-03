/**
 * Lanyard Tracking Resolvers
 *
 * GraphQL resolvers for per-day lanyard pickup/return tracking.
 *
 * Queries:
 *   - myLanyardStatus(eventId, date?): Volunteer's own status
 *   - lanyardStatuses(eventId, date?): All statuses (overseer)
 *   - lanyardSummary(eventId, date?): Aggregate counts (overseer)
 *
 * Mutations:
 *   - pickUpLanyard(eventId): Volunteer picks up
 *   - returnLanyard(eventId): Volunteer returns
 *   - overseerPickUpLanyard(eventVolunteerId): Overseer marks pickup
 *   - overseerReturnLanyard(eventVolunteerId): Overseer marks return
 *   - resetLanyard(eventId): Volunteer resets own status
 *   - overseerResetLanyard(eventVolunteerId): Overseer resets volunteer's status
 *
 * Authorization:
 *   Volunteer: requireAuth + attendant department check
 *   Overseer: requireAdmin + event access
 *
 * Used by: ./index.ts (resolver composition)
 */
import { Context } from '../context.js';
import { LanyardService } from '../../services/lanyardService.js';
import { requireAuth, requireEventAccess, tryRequireAdmin, tryRequireDeptAccessByEvent } from '../guards/auth.js';
import { AuthorizationError } from '../../utils/errors.js';
import {
  pickUpLanyardSchema,
  returnLanyardSchema,
  overseerLanyardSchema,
} from '../validators/lanyard.js';

/**
 * Resolve the attendant EventVolunteer for the current user.
 */
async function resolveAttendantVolunteer(
  context: Context,
  eventId: string
): Promise<{ eventVolunteerId: string }> {
  if (!context.user) throw new AuthorizationError('You must be logged in');
  const eventVolunteer = await context.prisma.eventVolunteer.findUnique({
    where: { userId_eventId: { userId: context.user.id, eventId } },
    include: { department: true },
  });

  if (!eventVolunteer || eventVolunteer.department?.departmentType !== 'ATTENDANT') {
    throw new AuthorizationError('Only attendant volunteers can access lanyard tracking');
  }

  return { eventVolunteerId: eventVolunteer.id };
}

/**
 * Format a LanyardCheckout (or virtual record) for the GraphQL response.
 */
function formatCheckout(checkout: any): any {
  return {
    ...checkout,
    date: checkout.date instanceof Date
      ? checkout.date.toISOString().split('T')[0]
      : checkout.date,
    volunteerName: checkout.volunteerName ??
      `${checkout.eventVolunteer?.user?.firstName ?? ''} ${checkout.eventVolunteer?.user?.lastName ?? ''}`.trim(),
  };
}

const lanyardResolvers = {
  Query: {
    myLanyardStatus: async (
      _parent: unknown,
      { eventId, date }: { eventId: string; date?: string },
      context: Context
    ) => {
      requireAuth(context);
      const { eventVolunteerId } = await resolveAttendantVolunteer(context, eventId);

      const lanyardService = new LanyardService(context.prisma);
      const result = await lanyardService.getMyStatus(eventVolunteerId, date);
      return result ? formatCheckout(result) : null;
    },

    lanyardStatuses: async (
      _parent: unknown,
      { eventId, date }: { eventId: string; date?: string },
      context: Context
    ) => {
      requireAuth(context);
      if (tryRequireAdmin(context)) {
        await requireEventAccess(context, eventId);
      } else {
        const access = await tryRequireDeptAccessByEvent(context, eventId);
        if (!access) throw new AuthorizationError('Department access required');
      }

      const lanyardService = new LanyardService(context.prisma);
      const statuses = await lanyardService.getStatuses(eventId, date);
      return statuses.map(formatCheckout);
    },

    lanyardSummary: async (
      _parent: unknown,
      { eventId, date }: { eventId: string; date?: string },
      context: Context
    ) => {
      requireAuth(context);
      if (tryRequireAdmin(context)) {
        await requireEventAccess(context, eventId);
      } else {
        const access = await tryRequireDeptAccessByEvent(context, eventId);
        if (!access) throw new AuthorizationError('Department access required');
      }

      const lanyardService = new LanyardService(context.prisma);
      return lanyardService.getSummary(eventId, date);
    },
  },

  Mutation: {
    pickUpLanyard: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAuth(context);
      pickUpLanyardSchema.parse({ eventId });
      const { eventVolunteerId } = await resolveAttendantVolunteer(context, eventId);

      const lanyardService = new LanyardService(context.prisma);
      const result = await lanyardService.pickUp(eventVolunteerId, eventId);
      return formatCheckout(result);
    },

    returnLanyard: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAuth(context);
      returnLanyardSchema.parse({ eventId });
      const { eventVolunteerId } = await resolveAttendantVolunteer(context, eventId);

      const lanyardService = new LanyardService(context.prisma);
      const result = await lanyardService.returnLanyard(eventVolunteerId, eventId);
      return formatCheckout(result);
    },

    overseerPickUpLanyard: async (
      _parent: unknown,
      { eventVolunteerId }: { eventVolunteerId: string },
      context: Context
    ) => {
      requireAuth(context);
      overseerLanyardSchema.parse({ eventVolunteerId });

      // Get eventId from volunteer record
      const vol = await context.prisma.eventVolunteer.findUnique({
        where: { id: eventVolunteerId },
      });
      if (!vol) throw new Error('Event volunteer not found');

      if (tryRequireAdmin(context)) {
        await requireEventAccess(context, vol.eventId);
      } else {
        const access = await tryRequireDeptAccessByEvent(context, vol.eventId);
        if (!access) throw new AuthorizationError('Department access required');
      }

      const lanyardService = new LanyardService(context.prisma);
      const result = await lanyardService.pickUp(eventVolunteerId, vol.eventId);
      return formatCheckout(result);
    },

    overseerReturnLanyard: async (
      _parent: unknown,
      { eventVolunteerId }: { eventVolunteerId: string },
      context: Context
    ) => {
      requireAuth(context);
      overseerLanyardSchema.parse({ eventVolunteerId });

      const vol = await context.prisma.eventVolunteer.findUnique({
        where: { id: eventVolunteerId },
      });
      if (!vol) throw new Error('Event volunteer not found');

      if (tryRequireAdmin(context)) {
        await requireEventAccess(context, vol.eventId);
      } else {
        const access = await tryRequireDeptAccessByEvent(context, vol.eventId);
        if (!access) throw new AuthorizationError('Department access required');
      }

      const lanyardService = new LanyardService(context.prisma);
      const result = await lanyardService.returnLanyard(eventVolunteerId, vol.eventId);
      return formatCheckout(result);
    },

    resetLanyard: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAuth(context);
      pickUpLanyardSchema.parse({ eventId });
      const { eventVolunteerId } = await resolveAttendantVolunteer(context, eventId);

      const lanyardService = new LanyardService(context.prisma);
      const result = await lanyardService.resetLanyard(eventVolunteerId, eventId);
      return formatCheckout(result);
    },

    overseerResetLanyard: async (
      _parent: unknown,
      { eventVolunteerId }: { eventVolunteerId: string },
      context: Context
    ) => {
      requireAuth(context);
      overseerLanyardSchema.parse({ eventVolunteerId });

      const vol = await context.prisma.eventVolunteer.findUnique({
        where: { id: eventVolunteerId },
      });
      if (!vol) throw new Error('Event volunteer not found');

      if (tryRequireAdmin(context)) {
        await requireEventAccess(context, vol.eventId);
      } else {
        const access = await tryRequireDeptAccessByEvent(context, vol.eventId);
        if (!access) throw new AuthorizationError('Department access required');
      }

      const lanyardService = new LanyardService(context.prisma);
      const result = await lanyardService.resetLanyard(eventVolunteerId, vol.eventId);
      return formatCheckout(result);
    },
  },
};

export default lanyardResolvers;
