/**
 * Area Resolvers
 *
 * Resolvers for area management: CRUD, captain assignment, and group queries.
 *
 * Authorization:
 *   - Admin (Overseer) mutations: requireAdmin + requireEventAccess
 *   - Volunteer queries (myAreaGroups): requireVolunteer
 *   - Read queries (area, departmentAreas, areaGroup): requireAuth + event access
 *
 * Used by: ./index.ts (resolver composition)
 * Implements: ../schema/area.ts
 */
import { Context } from '../context.js';
import {
  requireAuth,
  requireEventAccess,
  requireDeptAccess,
  tryRequireAdmin,
  resolveUserEventVolunteer,
} from '../guards/auth.js';
import { AreaService } from '../../services/areaService.js';
import { dateToTimeString } from '../../utils/time.js';
import type {
  CreateAreaInput,
  UpdateAreaInput,
  SetAreaCaptainInput,
  RemoveAreaCaptainInput,
  AcceptAreaCaptainInput,
  DeclineAreaCaptainInput,
} from '../validators/area.js';

/**
 * Check overseer OR assistant overseer access via area's department.
 */
async function requireAreaMgmtAccess(context: Context, areaService: AreaService, areaId: string) {
  if (tryRequireAdmin(context)) {
    const eventId = await areaService.getAreaEventId(areaId);
    await requireEventAccess(context, eventId);
    return;
  }
  const area = await context.prisma.area.findUnique({
    where: { id: areaId },
    select: { departmentId: true },
  });
  if (!area) throw new Error('Area not found');
  await requireDeptAccess(context, area.departmentId);
}

const areaResolvers = {
  Query: {
    area: async (
      _parent: unknown,
      { id }: { id: string },
      context: Context
    ) => {
      requireAuth(context);
      const areaService = new AreaService(context.prisma);
      const eventId = await areaService.getAreaEventId(id);

      if (context.user) {
        await requireEventAccess(context, eventId);
      }

      return areaService.getArea(id);
    },

    departmentAreas: async (
      _parent: unknown,
      { departmentId }: { departmentId: string },
      context: Context
    ) => {
      requireAuth(context);

      // Get event ID from department for access check
      const department = await context.prisma.department.findUnique({
        where: { id: departmentId },
        select: { eventId: true },
      });
      if (!department) return [];

      if (context.user) {
        await requireEventAccess(context, department.eventId);
      }

      const areaService = new AreaService(context.prisma);
      return areaService.getDepartmentAreas(departmentId);
    },

    areaGroup: async (
      _parent: unknown,
      { areaId, sessionId }: { areaId: string; sessionId: string },
      context: Context
    ) => {
      requireAuth(context);
      const areaService = new AreaService(context.prisma);
      const eventId = await areaService.getAreaEventId(areaId);

      if (context.user) {
        await requireEventAccess(context, eventId);
      }

      return areaService.getAreaGroup(areaId, sessionId);
    },

    myAreaGroups: async (
      _parent: unknown,
      _args: unknown,
      context: Context
    ) => {
      requireAuth(context);

      // Get the user's most recent EventVolunteer
      const eventVolunteer = await context.prisma.eventVolunteer.findFirst({
        where: { userId: context.user!.id },
        orderBy: { createdAt: 'desc' },
      });
      if (!eventVolunteer) return [];
      const eventVolunteerId = eventVolunteer.id;

      const areaService = new AreaService(context.prisma);
      return areaService.getMyAreaGroups(eventVolunteerId);
    },

    myCaptainAssignments: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAuth(context);
      const ev = await resolveUserEventVolunteer(context.user!.id, eventId, context.prisma);
      const areaService = new AreaService(context.prisma);
      return areaService.getMyCaptainAssignments(ev.id);
    },
  },

  Mutation: {
    createArea: async (
      _parent: unknown,
      { departmentId, input }: { departmentId: string; input: CreateAreaInput },
      context: Context
    ) => {
      if (tryRequireAdmin(context)) {
        const department = await context.prisma.department.findUnique({
          where: { id: departmentId },
          select: { eventId: true },
        });
        if (department) {
          await requireEventAccess(context, department.eventId);
        }
      } else {
        await requireDeptAccess(context, departmentId);
      }

      const areaService = new AreaService(context.prisma);
      return areaService.createArea(departmentId, input);
    },

    updateArea: async (
      _parent: unknown,
      { id, input }: { id: string; input: UpdateAreaInput },
      context: Context
    ) => {
      const areaService = new AreaService(context.prisma);
      await requireAreaMgmtAccess(context, areaService, id);

      return areaService.updateArea(id, input);
    },

    deleteArea: async (
      _parent: unknown,
      { id }: { id: string },
      context: Context
    ) => {
      const areaService = new AreaService(context.prisma);
      await requireAreaMgmtAccess(context, areaService, id);

      return areaService.deleteArea(id);
    },

    setAreaCaptain: async (
      _parent: unknown,
      { input }: { input: SetAreaCaptainInput },
      context: Context
    ) => {
      const areaService = new AreaService(context.prisma);
      await requireAreaMgmtAccess(context, areaService, input.areaId);

      return areaService.setAreaCaptain(input);
    },

    removeAreaCaptain: async (
      _parent: unknown,
      { input }: { input: RemoveAreaCaptainInput },
      context: Context
    ) => {
      const areaService = new AreaService(context.prisma);
      await requireAreaMgmtAccess(context, areaService, input.areaId);

      return areaService.removeAreaCaptain(input);
    },

    acceptAreaCaptain: async (
      _parent: unknown,
      { input }: { input: AcceptAreaCaptainInput },
      context: Context
    ) => {
      requireAuth(context);
      const areaCaptain = await context.prisma.areaCaptain.findUnique({
        where: { id: input.areaCaptainId },
        include: { area: { include: { department: { select: { eventId: true } } } } },
      });
      if (!areaCaptain) throw new Error('Captain assignment not found');

      const ev = await resolveUserEventVolunteer(
        context.user!.id,
        areaCaptain.area.department.eventId,
        context.prisma
      );
      const areaService = new AreaService(context.prisma);
      return areaService.acceptAreaCaptain(ev.id, input);
    },

    declineAreaCaptain: async (
      _parent: unknown,
      { input }: { input: DeclineAreaCaptainInput },
      context: Context
    ) => {
      requireAuth(context);
      const areaCaptain = await context.prisma.areaCaptain.findUnique({
        where: { id: input.areaCaptainId },
        include: { area: { include: { department: { select: { eventId: true } } } } },
      });
      if (!areaCaptain) throw new Error('Captain assignment not found');

      const ev = await resolveUserEventVolunteer(
        context.user!.id,
        areaCaptain.area.department.eventId,
        context.prisma
      );
      const areaService = new AreaService(context.prisma);
      return areaService.declineAreaCaptain(ev.id, input);
    },

    assignPostToArea: async (
      _parent: unknown,
      { postId, areaId }: { postId: string; areaId: string },
      context: Context
    ) => {
      const areaService = new AreaService(context.prisma);
      await requireAreaMgmtAccess(context, areaService, areaId);

      return areaService.assignPostToArea(postId, areaId);
    },

    removePostFromArea: async (
      _parent: unknown,
      { postId }: { postId: string },
      context: Context
    ) => {
      const post = await context.prisma.post.findUnique({
        where: { id: postId },
        select: { departmentId: true },
      });
      if (post) {
        if (tryRequireAdmin(context)) {
          const areaService = new AreaService(context.prisma);
          const eventId = await areaService.getPostEventId(postId);
          await requireEventAccess(context, eventId);
        } else {
          await requireDeptAccess(context, post.departmentId);
        }
      }

      const areaService = new AreaService(context.prisma);
      return areaService.removePostFromArea(postId);
    },
  },

  // Type resolvers
  Area: {
    postCount: (area: { _count?: { posts: number }; posts?: unknown[] }) => {
      return area._count?.posts ?? (area.posts as unknown[])?.length ?? 0;
    },
    startTime: (area: { startTime?: Date | null }) => {
      return area.startTime ? dateToTimeString(area.startTime) : null;
    },
    endTime: (area: { endTime?: Date | null }) => {
      return area.endTime ? dateToTimeString(area.endTime) : null;
    },
  },

  AreaCaptainAssignment: {
    area: (parent: { area?: unknown; areaId: string }, _args: unknown, context: Context) => {
      if (parent.area) return parent.area;
      return context.prisma.area.findUnique({ where: { id: parent.areaId } });
    },
    session: (parent: { session?: unknown; sessionId: string }, _args: unknown, context: Context) => {
      if (parent.session) return parent.session;
      return context.prisma.session.findUnique({ where: { id: parent.sessionId } });
    },
    eventVolunteer: (parent: { eventVolunteer?: unknown; eventVolunteerId: string }, _args: unknown, context: Context) => {
      if (parent.eventVolunteer) return parent.eventVolunteer;
      return context.prisma.eventVolunteer.findUnique({
        where: { id: parent.eventVolunteerId },
        include: { user: true },
      });
    },
  },
};

export default areaResolvers;
