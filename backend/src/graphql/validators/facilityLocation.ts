/**
 * Facility Location Input Validators
 *
 * Zod schemas for validating facility location inputs.
 *
 * Schemas:
 *   - createFacilityLocationSchema: Validate eventId, name, location, description, sortOrder
 *   - updateFacilityLocationSchema: Partial update (name, location, description, sortOrder)
 *
 * Used by: ../../services/facilityLocationService.ts
 */
import { z } from 'zod';

export const createFacilityLocationSchema = z.object({
  eventId: z.string().min(1),
  name: z.string().min(1).max(200),
  location: z.string().min(1).max(200),
  description: z.string().max(2000).optional(),
  sortOrder: z.number().int().min(0).optional(),
});

export const updateFacilityLocationSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  location: z.string().min(1).max(200).optional(),
  description: z.string().max(2000).nullable().optional(),
  sortOrder: z.number().int().min(0).optional(),
});

export type CreateFacilityLocationInput = z.infer<typeof createFacilityLocationSchema>;
export type UpdateFacilityLocationInput = z.infer<typeof updateFacilityLocationSchema>;
