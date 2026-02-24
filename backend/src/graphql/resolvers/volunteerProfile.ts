/**
 * VolunteerProfile & EventVolunteer Resolvers
 *
 * Handles persistent volunteer profiles and per-event volunteer instances.
 *
 * Queries:
 *   - volunteerProfiles: Get all profiles (optionally filtered by congregation)
 *   - volunteerProfilesByCircuit: Get all profiles in a circuit
 *   - searchVolunteerProfiles: Search profiles by name
 *   - volunteerProfile: Get a single profile by ID
 *   - eventVolunteer: Get a single event volunteer by ID
 *   - eventVolunteerByVolunteerId: Get event volunteer by login ID (e.g., "CA-A7X9K2")
 *
 * Mutations:
 *   - createVolunteerProfile: Create a new persistent profile
 *   - updateVolunteerProfile: Update an existing profile
 *   - deleteVolunteerProfile: Delete a profile (if no active event assignments)
 *   - addVolunteerToEvent: Add existing profile to an event (generates credentials)
 *   - removeVolunteerFromEvent: Remove volunteer from event
 *   - createAndAddVolunteer: Create profile + add to event in one step
 *   - regenerateVolunteerToken: Generate new login token for event volunteer
 *
 * Type Resolvers:
 *   - VolunteerProfile.congregation, eventVolunteers
 *   - EventVolunteer.volunteerProfile, event, department, role, assignments
 *
 * Schema: ../schema/volunteerProfile.ts
 */
import { Context } from '../context.js';
import { VolunteerProfile, EventVolunteer } from '@prisma/client';
import { GraphQLError } from 'graphql';
import { generateEventVolunteerId, generateToken, hashToken } from '../../utils/credentials.js';
import { encryptField } from '../../utils/encryption.js';
import { requireAdmin, requireEventAccess } from '../guards/auth.js';

// Input types
export interface CreateVolunteerProfileInput {
  firstName: string;
  lastName: string;
  email?: string;
  phone?: string;
  appointmentStatus?: 'PUBLISHER' | 'MINISTERIAL_SERVANT' | 'ELDER';
  notes?: string;
  congregationId: string;
}

export interface UpdateVolunteerProfileInput {
  firstName?: string;
  lastName?: string;
  email?: string;
  phone?: string;
  appointmentStatus?: 'PUBLISHER' | 'MINISTERIAL_SERVANT' | 'ELDER';
  notes?: string;
  congregationId?: string;
}

export interface AddVolunteerToEventInput {
  volunteerProfileId: string;
  eventId: string;
  departmentId?: string;
  roleId?: string;
}

export interface CreateAndAddVolunteerInput {
  firstName: string;
  lastName: string;
  email?: string;
  phone?: string;
  appointmentStatus?: 'PUBLISHER' | 'MINISTERIAL_SERVANT' | 'ELDER';
  notes?: string;
  congregationId: string;
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
    ): Promise<VolunteerProfile[]> => {
      requireAdmin(context);
      return context.prisma.volunteerProfile.findMany({
        where: args.congregationId ? { congregationId: args.congregationId } : {},
        orderBy: [{ lastName: 'asc' }, { firstName: 'asc' }],
      });
    },

    volunteerProfilesByCircuit: async (
      _parent: unknown,
      { circuitId }: { circuitId: string },
      context: Context
    ): Promise<VolunteerProfile[]> => {
      requireAdmin(context);
      return context.prisma.volunteerProfile.findMany({
        where: {
          congregation: { circuitId },
        },
        orderBy: [{ lastName: 'asc' }, { firstName: 'asc' }],
      });
    },

    searchVolunteerProfiles: async (
      _parent: unknown,
      args: { query: string; circuitId?: string },
      context: Context
    ): Promise<VolunteerProfile[]> => {
      requireAdmin(context);
      const searchTerms = args.query.toLowerCase().split(' ');

      return context.prisma.volunteerProfile.findMany({
        where: {
          AND: [
            args.circuitId ? { congregation: { circuitId: args.circuitId } } : {},
            {
              OR: [
                { firstName: { contains: args.query, mode: 'insensitive' } },
                { lastName: { contains: args.query, mode: 'insensitive' } },
                // Search for "first last" pattern
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
    ): Promise<VolunteerProfile | null> => {
      requireAdmin(context);
      return context.prisma.volunteerProfile.findUnique({
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
    createVolunteerProfile: async (
      _parent: unknown,
      { input }: { input: CreateVolunteerProfileInput },
      context: Context
    ): Promise<VolunteerProfile> => {
      requireAdmin(context);
      return context.prisma.volunteerProfile.create({
        data: {
          firstName: input.firstName,
          lastName: input.lastName,
          email: input.email,
          phone: input.phone,
          appointmentStatus: input.appointmentStatus || 'PUBLISHER',
          notes: input.notes,
          congregationId: input.congregationId,
        },
      });
    },

    updateVolunteerProfile: async (
      _parent: unknown,
      { id, input }: { id: string; input: UpdateVolunteerProfileInput },
      context: Context
    ): Promise<VolunteerProfile> => {
      requireAdmin(context);
      return context.prisma.volunteerProfile.update({
        where: { id },
        data: input,
      });
    },

    deleteVolunteerProfile: async (
      _parent: unknown,
      { id }: { id: string },
      context: Context
    ): Promise<boolean> => {
      requireAdmin(context);
      // Check if profile has any event volunteers
      const eventVolunteers = await context.prisma.eventVolunteer.findMany({
        where: { volunteerProfileId: id },
      });

      if (eventVolunteers.length > 0) {
        throw new GraphQLError('Cannot delete profile with active event assignments', {
          extensions: { code: 'BAD_REQUEST' },
        });
      }

      await context.prisma.volunteerProfile.delete({
        where: { id },
      });

      return true;
    },

    addVolunteerToEvent: async (
      _parent: unknown,
      { input }: { input: AddVolunteerToEventInput },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, input.eventId);
      const { volunteerProfileId, eventId, departmentId, roleId } = input;

      // Check if already added to this event
      const existing = await context.prisma.eventVolunteer.findUnique({
        where: {
          volunteerProfileId_eventId: {
            volunteerProfileId,
            eventId,
          },
        },
      });

      if (existing) {
        throw new GraphQLError('Volunteer already added to this event', {
          extensions: { code: 'BAD_REQUEST' },
        });
      }

      // Get event to determine prefix
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
      const prefix = event.template.eventType === 'CIRCUIT_ASSEMBLY' ? 'CA' : 'RC';
      const volunteerId = generateEventVolunteerId(prefix);
      const token = generateToken();
      const tokenHash = await hashToken(token);

      const eventVolunteer = await context.prisma.eventVolunteer.create({
        data: {
          volunteerId,
          tokenHash,
          encryptedToken: encryptField(token),
          volunteerProfileId,
          eventId,
          departmentId,
          roleId,
        },
        include: {
          volunteerProfile: true,
          event: { include: { template: true } },
        },
      });

      // Generate invite message
      const inviteMessage = generateInviteMessage(
        eventVolunteer.volunteerProfile.firstName,
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

    createAndAddVolunteer: async (
      _parent: unknown,
      { input }: { input: CreateAndAddVolunteerInput },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, input.eventId);
      const {
        firstName,
        lastName,
        email,
        phone,
        appointmentStatus,
        notes,
        congregationId,
        eventId,
        departmentId,
        roleId,
      } = input;

      // Get event to determine prefix
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
      const prefix = event.template.eventType === 'CIRCUIT_ASSEMBLY' ? 'CA' : 'RC';
      const volunteerId = generateEventVolunteerId(prefix);
      const token = generateToken();
      const tokenHash = await hashToken(token);

      // Create profile and event volunteer in transaction
      const result = await context.prisma.$transaction(async (tx) => {
        const profile = await tx.volunteerProfile.create({
          data: {
            firstName,
            lastName,
            email,
            phone,
            appointmentStatus: appointmentStatus || 'PUBLISHER',
            notes,
            congregationId,
          },
        });

        const eventVolunteer = await tx.eventVolunteer.create({
          data: {
            volunteerId,
            tokenHash,
            encryptedToken: encryptField(token),
            volunteerProfileId: profile.id,
            eventId,
            departmentId,
            roleId,
          },
          include: {
            volunteerProfile: true,
            event: { include: { template: true } },
          },
        });

        return eventVolunteer;
      });

      const inviteMessage = generateInviteMessage(
        result.volunteerProfile.firstName,
        result.event.template.name,
        volunteerId,
        token
      );

      return {
        eventVolunteer: result,
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
      // Check for active assignments
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
          volunteerProfile: true,
          event: { include: { template: true } },
        },
      });

      const inviteMessage = generateInviteMessage(
        eventVolunteer.volunteerProfile.firstName,
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

  VolunteerProfile: {
    congregation: async (profile: VolunteerProfile, _args: unknown, context: Context) => {
      return context.prisma.congregation.findUnique({
        where: { id: profile.congregationId },
      });
    },

    eventVolunteers: async (profile: VolunteerProfile, _args: unknown, context: Context) => {
      return context.prisma.eventVolunteer.findMany({
        where: { volunteerProfileId: profile.id },
      });
    },
  },

  EventVolunteer: {
    volunteerProfile: async (ev: EventVolunteer, _args: unknown, context: Context) => {
      return context.prisma.volunteerProfile.findUnique({
        where: { id: ev.volunteerProfileId },
        include: { congregation: true },
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
