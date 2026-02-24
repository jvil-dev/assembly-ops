/**
 * Facility Location Service
 *
 * Business logic for facility location guide management.
 * Overseers create locations (restrooms, first aid, exits, etc.)
 * that volunteers can reference during the event.
 *
 * Methods:
 *   - create(input): Create a facility location
 *   - update(id, input): Update a facility location
 *   - delete(id): Delete a facility location
 *   - getByEvent(eventId): Get all locations for an event
 *   - getEventId(id): Get event ID for access control
 *
 * Called by: ../graphql/resolvers/facilityLocation.ts
 */
import { PrismaClient, FacilityLocation } from '@prisma/client';
import { NotFoundError, ValidationError } from '../utils/errors.js';
import {
  createFacilityLocationSchema,
  updateFacilityLocationSchema,
  CreateFacilityLocationInput,
  UpdateFacilityLocationInput,
} from '../graphql/validators/facilityLocation.js';

export class FacilityLocationService {
  constructor(private prisma: PrismaClient) {}

  async create(input: CreateFacilityLocationInput): Promise<FacilityLocation> {
    const result = createFacilityLocationSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    return this.prisma.facilityLocation.create({
      data: result.data,
    });
  }

  async update(id: string, input: UpdateFacilityLocationInput): Promise<FacilityLocation> {
    const result = updateFacilityLocationSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const existing = await this.prisma.facilityLocation.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Facility location');
    }

    return this.prisma.facilityLocation.update({
      where: { id },
      data: result.data,
    });
  }

  async delete(id: string): Promise<boolean> {
    const existing = await this.prisma.facilityLocation.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Facility location');
    }

    await this.prisma.facilityLocation.delete({ where: { id } });
    return true;
  }

  async getByEvent(eventId: string): Promise<FacilityLocation[]> {
    return this.prisma.facilityLocation.findMany({
      where: { eventId },
      orderBy: { sortOrder: 'asc' },
    });
  }

  async getEventId(id: string): Promise<string> {
    const location = await this.prisma.facilityLocation.findUnique({
      where: { id },
      select: { eventId: true },
    });

    if (!location) {
      throw new NotFoundError('Facility location');
    }

    return location.eventId;
  }
}
