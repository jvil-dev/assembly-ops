import { Context } from '../context.js';
import { EventService } from '../../services/eventService.js';
import { requireAdmin, requireEventAccess } from '../guards/auth.js';
import { Event, EventTemplate, EventAdmin, Department, DepartmentType } from '@prisma/client';

// All 12 department types
const ALL_DEPARTMENT_TYPES: DepartmentType[] = [
  'ACCOUNTS',
  'ATTENDANT',
  'AUDIO_VIDEO',
  'BAPTISM',
  'CLEANING',
  'FIRST_AID',
  'INFORMATION_VOLUNTEER_SERVICE',
  'INSTALLATION',
  'LOST_FOUND_CHECKROOM',
  'PARKING',
  'ROOMING',
  'TRUCKING_EQUIPMENT',
];

const eventResolvers = {
  Query: {
    eventTemplates: async (
      _parent: unknown,
      { serviceYear }: { serviceYear?: number },
      context: Context
    ): Promise<EventTemplate[]> => {
      const eventService = new EventService(context.prisma);
      return eventService.getEventTemplates(serviceYear);
    },

    myEvents: async (_parent: unknown, _args: unknown, context: Context): Promise<EventAdmin[]> => {
      requireAdmin(context);
      const eventService = new EventService(context.prisma);
      return eventService.getMyEvents(context.admin.id);
    },

    event: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAdmin(context);
      await requireEventAccess(context, id);
      const eventService = new EventService(context.prisma);
      return eventService.getEvent(id);
    },

    eventDepartments: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ): Promise<Department[]> => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);
      const eventService = new EventService(context.prisma);
      return eventService.getEventDepartments(eventId);
    },

    availableDepartments: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ): Promise<DepartmentType[]> => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);

      const claimedDepartments = await context.prisma.department.findMany({
        where: { eventId },
        select: { departmentType: true },
      });

      const claimedTypes = claimedDepartments.map((d) => d.departmentType);
      return ALL_DEPARTMENT_TYPES.filter((t) => !claimedTypes.includes(t));
    },
  },

  Mutation: {
    activateEvent: async (
      _parent: unknown,
      { input }: { input: { templateId: string } },
      context: Context
    ) => {
      requireAdmin(context);
      const eventService = new EventService(context.prisma);
      return eventService.activateEvent(input, context.admin.id);
    },

    joinEvent: async (
      _parent: unknown,
      { input }: { input: { joinCode: string } },
      context: Context
    ) => {
      requireAdmin(context);
      const eventService = new EventService(context.prisma);
      return eventService.joinEvent(input, context.admin.id);
    },

    claimDepartment: async (
      _parent: unknown,
      { input }: { input: { eventId: string; departmentType: DepartmentType } },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, input.eventId);
      const eventService = new EventService(context.prisma);
      return eventService.claimDepartment(input, context.admin.id);
    },
  },

  Event: {
    name: (event: Event & { template: EventTemplate }) => event.template.name,
    eventType: (event: Event & { template: EventTemplate }) => event.template.eventType,
    venue: (event: Event & { template: EventTemplate }) => event.template.venue,
    address: (event: Event & { template: EventTemplate }) => event.template.address,
    startDate: (event: Event & { template: EventTemplate }) => event.template.startDate,
    endDate: (event: Event & { template: EventTemplate }) => event.template.endDate,
    volunteerCount: async (event: Event, _args: unknown, context: Context) => {
      const count = await context.prisma.volunteer.count({
        where: { eventId: event.id },
      });
      return count;
    },
  },

  EventTemplate: {
    isActivated: async (template: EventTemplate, _args: unknown, context: Context) => {
      if (!context.admin) return false;
      const event = await context.prisma.event.findFirst({
        where: {
          templateId: template.id,
          admins: { some: { adminId: context.admin.id } },
        },
      });
      return !!event;
    },
  },

  Department: {
    volunteerCount: async (dept: Department, _args: unknown, context: Context) => {
      return context.prisma.volunteer.count({
        where: { departmentId: dept.id },
      });
    },
    isClaimed: (dept: Department & { overseer?: EventAdmin | null }) => {
      return !!dept.overseer;
    },
  },
};

export default eventResolvers;
