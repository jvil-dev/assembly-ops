/**
 * Facility Location Resolvers
 *
 * GraphQL resolvers for facility location guide management.
 *
 * Authorization:
 *   - facilityLocations: requireAuth (read)
 *   - createFacilityLocation / updateFacilityLocation / deleteFacilityLocation: requireAdmin + requireEventAccess
 *
 * Used by: ./index.ts (resolver composition)
 */
import { Context } from '../context.js';
import { FacilityLocationService } from '../../services/facilityLocationService.js';
import { requireAuth, requireAdmin, requireEventAccess } from '../guards/auth.js';
import {
  CreateFacilityLocationInput,
  UpdateFacilityLocationInput,
} from '../validators/facilityLocation.js';

const facilityLocationResolvers = {
  Query: {
    facilityLocations: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAuth(context);

      const service = new FacilityLocationService(context.prisma);
      return service.getByEvent(eventId);
    },
  },

  Mutation: {
    createFacilityLocation: async (
      _parent: unknown,
      { input }: { input: CreateFacilityLocationInput },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, input.eventId);

      const service = new FacilityLocationService(context.prisma);
      return service.create(input);
    },

    updateFacilityLocation: async (
      _parent: unknown,
      { id, input }: { id: string; input: UpdateFacilityLocationInput },
      context: Context
    ) => {
      requireAdmin(context);

      const service = new FacilityLocationService(context.prisma);
      const eventId = await service.getEventId(id);
      await requireEventAccess(context, eventId);

      return service.update(id, input);
    },

    deleteFacilityLocation: async (
      _parent: unknown,
      { id }: { id: string },
      context: Context
    ) => {
      requireAdmin(context);

      const service = new FacilityLocationService(context.prisma);
      const eventId = await service.getEventId(id);
      await requireEventAccess(context, eventId);

      return service.delete(id);
    },
  },
};

export default facilityLocationResolvers;
