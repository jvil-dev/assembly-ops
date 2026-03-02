/**
 * Lanyard Tracking Input Validators
 *
 * Zod schemas for validating lanyard tracking inputs.
 *
 * Schemas:
 *   - pickUpLanyardSchema: eventId
 *   - returnLanyardSchema: eventId
 *   - overseerLanyardSchema: eventVolunteerId
 *   - lanyardStatusesSchema: eventId + optional date (YYYY-MM-DD)
 *
 * Used by: ../resolvers/lanyard.ts
 */
import { z } from 'zod';

export const pickUpLanyardSchema = z.object({
  eventId: z.string().min(1, 'Event ID is required'),
});

export const returnLanyardSchema = z.object({
  eventId: z.string().min(1, 'Event ID is required'),
});

export const overseerLanyardSchema = z.object({
  eventVolunteerId: z.string().min(1, 'Event volunteer ID is required'),
});

export const lanyardStatusesSchema = z.object({
  eventId: z.string().min(1, 'Event ID is required'),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Date must be in YYYY-MM-DD format').optional(),
});

export type PickUpLanyardInput = z.infer<typeof pickUpLanyardSchema>;
export type ReturnLanyardInput = z.infer<typeof returnLanyardSchema>;
export type OverseerLanyardInput = z.infer<typeof overseerLanyardSchema>;
export type LanyardStatusesInput = z.infer<typeof lanyardStatusesSchema>;
