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
  requireAdmin,
  requireAuth,
  requireVolunteer,
  requireEventAccess,
} from '../guards/auth.js';
import { AreaService } from '../../services/areaService.js';
import type {
  CreateAreaInput,
  UpdateAreaInput,
  SetAreaCaptainInput,
  RemoveAreaCaptainInput,
} from '../validators/area.js';

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
      requireVolunteer(context);

      // Resolve the eventVolunteerId — try direct first, then bridge
      let eventVolunteerId = context.volunteer!.id;

      const eventVolunteer = await context.prisma.eventVolunteer.findUnique({
        where: { id: eventVolunteerId },
      });

      const areaService = new AreaService(context.prisma);
      return areaService.getMyAreaGroups(eventVolunteerId);
    },
  },

  Mutation: {
    createArea: async (
      _parent: unknown,
      { departmentId, input }: { departmentId: string; input: CreateAreaInput },
      context: Context
    ) => {
      requireAdmin(context);

      const department = await context.prisma.department.findUnique({
        where: { id: departmentId },
        select: { eventId: true },
      });
      if (department) {
        await requireEventAccess(context, department.eventId);
      }

      const areaService = new AreaService(context.prisma);
      return areaService.createArea(departmentId, input);
    },

    updateArea: async (
      _parent: unknown,
      { id, input }: { id: string; input: UpdateAreaInput },
      context: Context
    ) => {
      requireAdmin(context);
      const areaService = new AreaService(context.prisma);
      const eventId = await areaService.getAreaEventId(id);
      await requireEventAccess(context, eventId);

      return areaService.updateArea(id, input);
    },

    deleteArea: async (
      _parent: unknown,
      { id }: { id: string },
      context: Context
    ) => {
      requireAdmin(context);
      const areaService = new AreaService(context.prisma);
      const eventId = await areaService.getAreaEventId(id);
      await requireEventAccess(context, eventId);

      return areaService.deleteArea(id);
    },

    setAreaCaptain: async (
      _parent: unknown,
      { input }: { input: SetAreaCaptainInput },
      context: Context
    ) => {
      requireAdmin(context);
      const areaService = new AreaService(context.prisma);
      const eventId = await areaService.getAreaEventId(input.areaId);
      await requireEventAccess(context, eventId);

      return areaService.setAreaCaptain(input);
    },

    removeAreaCaptain: async (
      _parent: unknown,
      { input }: { input: RemoveAreaCaptainInput },
      context: Context
    ) => {
      requireAdmin(context);
      const areaService = new AreaService(context.prisma);
      const eventId = await areaService.getAreaEventId(input.areaId);
      await requireEventAccess(context, eventId);

      return areaService.removeAreaCaptain(input);
    },

    assignPostToArea: async (
      _parent: unknown,
      { postId, areaId }: { postId: string; areaId: string },
      context: Context
    ) => {
      requireAdmin(context);
      const areaService = new AreaService(context.prisma);
      const eventId = await areaService.getAreaEventId(areaId);
      await requireEventAccess(context, eventId);

      return areaService.assignPostToArea(postId, areaId);
    },

    removePostFromArea: async (
      _parent: unknown,
      { postId }: { postId: string },
      context: Context
    ) => {
      requireAdmin(context);
      const areaService = new AreaService(context.prisma);
      const eventId = await areaService.getPostEventId(postId);
      await requireEventAccess(context, eventId);

      return areaService.removePostFromArea(postId);
    },
  },

  // Type resolvers
  Area: {
    postCount: (area: { _count?: { posts: number }; posts?: unknown[] }) => {
      return area._count?.posts ?? (area.posts as unknown[])?.length ?? 0;
    },
  },
};

export default areaResolvers;
