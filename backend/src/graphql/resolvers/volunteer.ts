import { Context } from '../context.js';
import { VolunteerService, CreatedVolunteer } from '../../services/volunteerService.js';
import { requireAdmin, requireVolunteer, requireEventAccess } from '../guards/auth.js';
import { Volunteer } from '@prisma/client';
import {
  CreateVolunteerInput,
  CreateVolunteersInput,
  LoginVolunteerInput,
} from '../validators/volunteer.js';

const volunteerResolvers = {
  Query: {
    volunteer: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAdmin(context);
      const volunteerService = new VolunteerService(context.prisma);
      const volunteer = await volunteerService.getVolunteer(id);
      if (volunteer) {
        await requireEventAccess(context, volunteer.eventId);
      }
      return volunteer;
    },

    volunteers: async (
      _parent: unknown,
      { eventId, departmentId }: { eventId: string; departmentId?: string },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);
      const volunteerService = new VolunteerService(context.prisma);
      return volunteerService.getEventVolunteers(eventId, departmentId);
    },

    myVolunteerProfile: async (_parent: unknown, _args: unknown, context: Context) => {
      requireVolunteer(context);
      const volunteerService = new VolunteerService(context.prisma);
      return volunteerService.getVolunteer(context.volunteer.id);
    },
  },

  Mutation: {
    createVolunteer: async (
      _parent: unknown,
      { eventId, input }: { eventId: string; input: CreateVolunteerInput },
      context: Context
    ): Promise<CreatedVolunteer> => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);

      // Get admin's department in this event
      const eventAdmin = await context.prisma.eventAdmin.findUnique({
        where: {
          adminId_eventId: {
            adminId: context.admin.id,
            eventId,
          },
        },
      });

      const volunteerService = new VolunteerService(context.prisma);
      return volunteerService.createVolunteer(
        eventId,
        input,
        eventAdmin?.departmentId || undefined
      );
    },

    createVolunteers: async (
      _parent: unknown,
      { input }: { input: CreateVolunteersInput },
      context: Context
    ): Promise<CreatedVolunteer[]> => {
      requireAdmin(context);
      await requireEventAccess(context, input.eventId);

      // Get admin's department in this event
      const eventAdmin = await context.prisma.eventAdmin.findUnique({
        where: {
          adminId_eventId: {
            adminId: context.admin.id,
            eventId: input.eventId,
          },
        },
      });

      const volunteerService = new VolunteerService(context.prisma);
      return volunteerService.createVolunteers(input, eventAdmin?.departmentId || undefined);
    },

    updateVolunteer: async (
      _parent: unknown,
      { id, input }: { id: string; input: Partial<CreateVolunteerInput> },
      context: Context
    ) => {
      requireAdmin(context);

      // Get volunteer to check event access
      const volunteer = await context.prisma.volunteer.findUnique({
        where: { id },
      });

      if (volunteer) {
        await requireEventAccess(context, volunteer.eventId);
      }

      const volunteerService = new VolunteerService(context.prisma);
      return volunteerService.updateVolunteer(id, input);
    },

    deleteVolunteer: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAdmin(context);

      // Get volunteer to check event access
      const volunteer = await context.prisma.volunteer.findUnique({
        where: { id },
      });

      if (volunteer) {
        await requireEventAccess(context, volunteer.eventId);
      }

      const volunteerService = new VolunteerService(context.prisma);
      return volunteerService.deleteVolunteer(id);
    },

    regenerateVolunteerCredentials: async (
      _parent: unknown,
      { id }: { id: string },
      context: Context
    ) => {
      requireAdmin(context);

      // Get volunteer to check event access
      const volunteer = await context.prisma.volunteer.findUnique({
        where: { id },
      });

      if (volunteer) {
        await requireEventAccess(context, volunteer.eventId);
      }

      const volunteerService = new VolunteerService(context.prisma);
      return volunteerService.regenerateCredentials(id);
    },

    loginVolunteer: async (
      _parent: unknown,
      { input }: { input: LoginVolunteerInput },
      context: Context
    ) => {
      const volunteerService = new VolunteerService(context.prisma);
      const result = await volunteerService.loginVolunteer(input);

      // Fetch full volunteer for response
      const volunteer = await volunteerService.getVolunteer(result.volunteer.id);

      return {
        volunteer,
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
        expiresIn: result.tokens.expiresIn,
      };
    },
  },

  Volunteer: {
    fullName: (volunteer: Volunteer): string => {
      return `${volunteer.firstName} ${volunteer.lastName}`;
    },
  },
};

export default volunteerResolvers;
