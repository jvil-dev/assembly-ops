/**
 * User Profile & EventVolunteer Resolvers
 *
 * Handles persistent user profiles and per-event volunteer instances.
 * Users are the persistent identity; EventVolunteers are per-event credentials.
 *
 * Queries:
 *   - volunteerProfiles: Search users by name/congregation (replaces old VolunteerProfile queries)
 *   - volunteerProfilesByCircuit: Get users in a circuit
 *   - searchVolunteerProfiles: Search by name
 *   - volunteerProfile: Get a single user by ID
 *   - eventVolunteer: Get a single event volunteer by ID
 *   - eventVolunteerByVolunteerId: Get event volunteer by login ID
 *
 * Mutations:
 *   - addVolunteerToEvent: Add existing User to an event (generates credentials)
 *   - removeVolunteerFromEvent: Remove volunteer from event
 *   - regenerateVolunteerToken: Generate new login token for event volunteer
 *
 * Schema: ../schema/volunteerProfile.ts
 */
import { Context } from '../context.js';
import { User, EventVolunteer } from '@prisma/client';
import { GraphQLError } from 'graphql';
import { generateEventVolunteerId, generateToken, hashToken } from '../../utils/credentials.js';
import { encryptField } from '../../utils/encryption.js';
import { requireAdmin, requireEventAccess } from '../guards/auth.js';

// Input types
export interface AddVolunteerToEventInput {
  userId: string;
  eventId: string;
  departmentId?: string;
  roleId?: string;
}

/**
 * Generate invite message for a volunteer
 */
function generateInviteMessage(
  firstName: string,
  eventName: string,
  volunteerId: string,
  token: string
): string {
  return `Hi ${firstName}!

You've been added to ${eventName}!

Download the AssemblyOps app:
[App Store Link]

Your login credentials:
Volunteer ID: ${volunteerId}
Token: ${token}

Questions? Contact your department overseer.`;
}

const volunteerProfileResolvers = {
  Query: {
    volunteerProfiles: async (
      _parent: unknown,
      args: { congregationId?: string },
      context: Context
    ): Promise<User[]> => {
      requireAdmin(context);
      return context.prisma.user.findMany({
        where: args.congregationId ? { congregationId: args.congregationId } : {},
        orderBy: [{ lastName: 'asc' }, { firstName: 'asc' }],
      });
    },

    volunteerProfilesByCircuit: async (
      _parent: unknown,
      { circuitId }: { circuitId: string },
      context: Context
    ): Promise<User[]> => {
      requireAdmin(context);
      return context.prisma.user.findMany({
        where: {
          congregationRef: { circuitId },
        },
        orderBy: [{ lastName: 'asc' }, { firstName: 'asc' }],
      });
    },

    searchVolunteerProfiles: async (
      _parent: unknown,
      args: { query: string; circuitId?: string },
      context: Context
    ): Promise<User[]> => {
      requireAdmin(context);
      const searchTerms = args.query.toLowerCase().split(' ');

      return context.prisma.user.findMany({
        where: {
          AND: [
            args.circuitId ? { congregationRef: { circuitId: args.circuitId } } : {},
            {
              OR: [
                { firstName: { contains: args.query, mode: 'insensitive' } },
                { lastName: { contains: args.query, mode: 'insensitive' } },
                ...(searchTerms.length === 2
                  ? [
                      {
                        AND: [
                          { firstName: { contains: searchTerms[0], mode: 'insensitive' as const } },
                          { lastName: { contains: searchTerms[1], mode: 'insensitive' as const } },
                        ],
                      },
                    ]
                  : []),
              ],
            },
          ],
        },
        orderBy: [{ lastName: 'asc' }, { firstName: 'asc' }],
        take: 20,
      });
    },

    volunteerProfile: async (
      _parent: unknown,
      { id }: { id: string },
      context: Context
    ): Promise<User | null> => {
      requireAdmin(context);
      return context.prisma.user.findUnique({
        where: { id },
      });
    },

    eventVolunteer: async (
      _parent: unknown,
      { id }: { id: string },
      context: Context
    ): Promise<EventVolunteer | null> => {
      requireAdmin(context);
      const ev = await context.prisma.eventVolunteer.findUnique({
        where: { id },
        select: { id: true, eventId: true },
      });
      if (!ev) return null;
      await requireEventAccess(context, ev.eventId);
      return context.prisma.eventVolunteer.findUnique({
        where: { id },
      });
    },

    eventVolunteerByVolunteerId: async (
      _parent: unknown,
      { volunteerId }: { volunteerId: string },
      context: Context
    ): Promise<EventVolunteer | null> => {
      requireAdmin(context);
      const ev = await context.prisma.eventVolunteer.findUnique({
        where: { volunteerId },
        select: { id: true, eventId: true },
      });
      if (!ev) return null;
      await requireEventAccess(context, ev.eventId);
      return context.prisma.eventVolunteer.findUnique({
        where: { volunteerId },
      });
    },
  },

  Mutation: {
    addVolunteerToEvent: async (
      _parent: unknown,
      { input }: { input: AddVolunteerToEventInput },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, input.eventId);
      const { userId, eventId, departmentId, roleId } = input;

      // Check if already added to this event
      const existing = await context.prisma.eventVolunteer.findUnique({
        where: {
          userId_eventId: {
            userId,
            eventId,
          },
        },
      });

      if (existing) {
        throw new GraphQLError('Volunteer already added to this event', {
          extensions: { code: 'BAD_REQUEST' },
        });
      }

      // Get the user for invite message
      const user = await context.prisma.user.findUnique({
        where: { id: userId },
      });

      if (!user) {
        throw new GraphQLError('User not found', {
          extensions: { code: 'NOT_FOUND' },
        });
      }

      // Get event name
      const event = await context.prisma.event.findUnique({
        where: { id: eventId },
        include: { template: true },
      });

      if (!event) {
        throw new GraphQLError('Event not found', {
          extensions: { code: 'NOT_FOUND' },
        });
      }

      // Generate credentials
      const volunteerId = generateEventVolunteerId();
      const token = generateToken();
      const tokenHash = await hashToken(token);

      const eventVolunteer = await context.prisma.eventVolunteer.create({
        data: {
          volunteerId,
          tokenHash,
          encryptedToken: encryptField(token),
          userId,
          eventId,
          departmentId,
          roleId,
        },
        include: {
          user: true,
          event: { include: { template: true } },
        },
      });

      const inviteMessage = generateInviteMessage(
        eventVolunteer.user.firstName,
        eventVolunteer.event.template.name,
        volunteerId,
        token
      );

      return {
        eventVolunteer,
        volunteerId,
        token,
        inviteMessage,
      };
    },

    removeVolunteerFromEvent: async (
      _parent: unknown,
      { eventVolunteerId }: { eventVolunteerId: string },
      context: Context
    ): Promise<boolean> => {
      requireAdmin(context);
      const ev = await context.prisma.eventVolunteer.findUnique({
        where: { id: eventVolunteerId },
        select: { eventId: true },
      });
      if (!ev) {
        throw new GraphQLError('Event volunteer not found', {
          extensions: { code: 'NOT_FOUND' },
        });
      }
      await requireEventAccess(context, ev.eventId);

      const assignments = await context.prisma.scheduleAssignment.findMany({
        where: { eventVolunteerId },
      });

      if (assignments.length > 0) {
        throw new GraphQLError('Cannot remove volunteer with active assignments', {
          extensions: { code: 'BAD_REQUEST' },
        });
      }

      await context.prisma.eventVolunteer.delete({
        where: { id: eventVolunteerId },
      });

      return true;
    },

    addVolunteerByUserId: async (
      _parent: unknown,
      { eventId, userId: userShortId, departmentId }: { eventId: string; userId: string; departmentId?: string },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);
      const { VolunteerService } = await import('../../services/volunteerService.js');
      const volunteerService = new VolunteerService(context.prisma);
      return volunteerService.addVolunteerByUserId(eventId, userShortId, context.admin!.id, departmentId);
    },

    regenerateVolunteerToken: async (
      _parent: unknown,
      { eventVolunteerId }: { eventVolunteerId: string },
      context: Context
    ) => {
      requireAdmin(context);
      const evRecord = await context.prisma.eventVolunteer.findUnique({
        where: { id: eventVolunteerId },
        select: { eventId: true },
      });
      if (!evRecord) {
        throw new GraphQLError('Event volunteer not found', {
          extensions: { code: 'NOT_FOUND' },
        });
      }
      await requireEventAccess(context, evRecord.eventId);

      const token = generateToken();
      const tokenHash = await hashToken(token);

      const eventVolunteer = await context.prisma.eventVolunteer.update({
        where: { id: eventVolunteerId },
        data: { tokenHash, encryptedToken: encryptField(token) },
        include: {
          user: true,
          event: { include: { template: true } },
        },
      });

      const inviteMessage = generateInviteMessage(
        eventVolunteer.user.firstName,
        eventVolunteer.event.template.name,
        eventVolunteer.volunteerId,
        token
      );

      return {
        eventVolunteer,
        volunteerId: eventVolunteer.volunteerId,
        token,
        inviteMessage,
      };
    },
  },

  // Type resolvers for User (as volunteer profile)
  VolunteerProfile: {
    congregation: async (user: User, _args: unknown, context: Context) => {
      if (!(user as User & { congregationId?: string | null }).congregationId) return null;
      return context.prisma.congregation.findUnique({
        where: { id: (user as User & { congregationId: string }).congregationId },
      });
    },

    eventVolunteers: async (user: User, _args: unknown, context: Context) => {
      return context.prisma.eventVolunteer.findMany({
        where: { userId: user.id },
      });
    },
  },

  EventVolunteer: {
    user: async (ev: EventVolunteer, _args: unknown, context: Context) => {
      return context.prisma.user.findUnique({
        where: { id: ev.userId },
      });
    },

    event: async (ev: EventVolunteer, _args: unknown, context: Context) => {
      return context.prisma.event.findUnique({
        where: { id: ev.eventId },
        include: { template: true },
      });
    },

    department: async (ev: EventVolunteer, _args: unknown, context: Context) => {
      if (!ev.departmentId) return null;
      return context.prisma.department.findUnique({
        where: { id: ev.departmentId },
      });
    },

    role: async (ev: EventVolunteer, _args: unknown, context: Context) => {
      if (!ev.roleId) return null;
      return context.prisma.role.findUnique({
        where: { id: ev.roleId },
      });
    },

    assignments: async (ev: EventVolunteer, _args: unknown, context: Context) => {
      return context.prisma.scheduleAssignment.findMany({
        where: { eventVolunteerId: ev.id },
      });
    },
  },
};

export default volunteerProfileResolvers;
