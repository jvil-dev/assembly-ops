/**
 * Event Resolvers
 *
 * Handles event management: templates, department purchasing, hierarchy.
 *
 * Queries:
 *   - eventTemplates: Get available templates (optionally filtered by service year)
 *   - myEvents: Get all events the current overseer is associated with
 *   - myAllEvents: Get all events for the current user (overseer + volunteer)
 *   - event: Get a single event by ID (requires event access)
 *   - eventDepartments: Get all departments for an event
 *   - availableDepartments: Get department types not yet claimed
 *   - eventAdmins: Get all overseers for an event (requires event access)
 *   - discoverEvents: Get public events available to join
 *   - departmentInfo: Get detailed department info with hierarchy
 *
 * Mutations:
 *   - purchaseDepartment: Purchase a department (creates EventAdmin + Department + access code)
 *   - joinDepartmentByAccessCode: Volunteer joins via access code
 *   - setDepartmentPrivacy: Toggle department public/private
 *   - assignHierarchyRole: Assign hierarchy role to volunteer
 *   - removeHierarchyRole: Remove hierarchy role
 *
 * Type Resolvers:
 *   - Event: name, eventType, venue, etc. (derived from template)
 *   - Event.volunteerCount: Counts volunteers in this event
 *   - EventTemplate.isActivated: Whether this overseer has activated this template
 *   - Department.volunteerCount: Counts volunteers in this department
 *   - Department.isClaimed: Whether someone has claimed this department
 *   - Department.hierarchyRoles: Hierarchy assignments for this department
 *
 * Dependencies:
 *   - EventService (../../services/eventService.ts): Business logic
 *   - Guards (../guards/auth.ts): requireAdmin, requireAuth, requireUser, requireEventAccess
 *
 * Schema: ../schema/event.ts
 */
import { Context } from '../context.js';
import { EventService } from '../../services/eventService.js';
import { requireAdmin, requireAuth, requireUser, requireEventAccess } from '../guards/auth.js';
import { Event, EventAdmin, Department, DepartmentType } from '@prisma/client';
import type { AssignHierarchyRoleInput } from '../validators/event.js';

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
    myEvents: async (_parent: unknown, _args: unknown, context: Context): Promise<EventAdmin[]> => {
      requireAdmin(context);
      const eventService = new EventService(context.prisma);
      return eventService.getMyEvents(context.user!.id);
    },

    myAllEvents: async (_parent: unknown, _args: unknown, context: Context) => {
      requireUser(context);
      const eventService = new EventService(context.prisma);
      return eventService.getMyAllEvents(context.user!.id);
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

    eventAdmins: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ): Promise<EventAdmin[]> => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);
      const eventService = new EventService(context.prisma);
      return eventService.getEventAdmins(eventId);
    },

    discoverEvents: async (
      _parent: unknown,
      { eventType, state, language, circuitCode }: { eventType?: string; state?: string; language?: string; circuitCode?: string },
      context: Context
    ) => {
      requireAuth(context);
      const where: Record<string, unknown> = { isPublic: true };
      if (eventType) where.eventType = eventType;
      if (state) where.state = state;
      if (language) where.language = language;
      if (circuitCode) {
        where.OR = [
          { circuit: circuitCode },
          { circuit: null },
        ];
      }
      return context.prisma.event.findMany({
        where,
        include: { admins: true, departments: true, sessions: true, roles: true },
        orderBy: { startDate: 'asc' },
      });
    },

    departmentInfo: async (
      _parent: unknown,
      { departmentId }: { departmentId: string },
      context: Context
    ) => {
      requireAuth(context);
      const eventService = new EventService(context.prisma);
      return eventService.getDepartmentInfo(departmentId);
    },
  },

  Mutation: {
    purchaseDepartment: async (
      _parent: unknown,
      { input }: { input: { eventId: string; departmentType: DepartmentType } },
      context: Context
    ) => {
      requireAdmin(context);
      const eventService = new EventService(context.prisma);
      return eventService.purchaseDepartment(input, context.user!.id);
    },

    joinDepartmentByAccessCode: async (
      _parent: unknown,
      { input }: { input: { accessCode: string } },
      context: Context
    ) => {
      requireUser(context);
      const eventService = new EventService(context.prisma);
      return eventService.joinDepartmentByAccessCode(input, context.user!.id);
    },

    setDepartmentPrivacy: async (
      _parent: unknown,
      { departmentId, isPublic }: { departmentId: string; isPublic: boolean },
      context: Context
    ) => {
      requireAdmin(context);
      const eventService = new EventService(context.prisma);
      return eventService.setDepartmentPrivacy(departmentId, isPublic, context.user!.id);
    },

    assignHierarchyRole: async (
      _parent: unknown,
      { input }: { input: AssignHierarchyRoleInput },
      context: Context
    ) => {
      requireAdmin(context);
      const eventService = new EventService(context.prisma);
      return eventService.assignHierarchyRole(input, context.user!.id);
    },

    removeHierarchyRole: async (
      _parent: unknown,
      { departmentId, eventVolunteerId }: { departmentId: string; eventVolunteerId: string },
      context: Context
    ) => {
      requireAdmin(context);
      const eventService = new EventService(context.prisma);
      return eventService.removeHierarchyRole(departmentId, eventVolunteerId, context.user!.id);
    },
  },

  Event: {
    volunteerCount: async (event: Event, _args: unknown, context: Context) => {
      const count = await context.prisma.eventVolunteer.count({
        where: { eventId: event.id },
      });
      return count;
    },
  },

  Department: {
    volunteerCount: async (dept: Department, _args: unknown, context: Context) => {
      return context.prisma.eventVolunteer.count({
        where: { departmentId: dept.id },
      });
    },
    isClaimed: (dept: Department & { overseer?: EventAdmin | null }) => {
      return !!dept.overseer;
    },
    hierarchyRoles: async (dept: Department, _args: unknown, context: Context) => {
      return context.prisma.departmentHierarchy.findMany({
        where: { departmentId: dept.id },
        include: {
          eventVolunteer: {
            include: { user: true },
          },
        },
        orderBy: { assignedAt: 'asc' },
      });
    },
  },
};

export default eventResolvers;
