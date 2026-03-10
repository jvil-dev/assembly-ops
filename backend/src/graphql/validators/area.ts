/**
 * Area Validators
 *
 * Zod validation schemas for area-related inputs.
 *
 * Schemas:
 *   - createAreaSchema: Validates area creation input (name required, 1-100 chars)
 *   - updateAreaSchema: Validates area update input (all fields optional)
 *   - setAreaCaptainSchema: Validates captain assignment (areaId, sessionId, eventVolunteerId, forceAssigned?, acceptedDeadline?)
 *   - removeAreaCaptainSchema: Validates captain removal (areaId, sessionId)
 *   - acceptAreaCaptainSchema: Validates captain acceptance (areaCaptainId)
 *   - declineAreaCaptainSchema: Validates captain decline (areaCaptainId, reason?)
 *
 * Business rules enforced:
 *   - Area name: 1-100 characters, trimmed
 *   - Description: max 500 characters
 *   - Sort order: non-negative integer
 *   - All IDs: non-empty strings
 *   - Decline reason: max 500 characters, trimmed
 */
import { z } from 'zod';

const timeStringSchema = z
  .string()
  .regex(/^\d{2}:\d{2}$/, 'Time must be in HH:mm format')
  .nullish()
  .transform((v) => v || null);

export const createAreaSchema = z.object({
  name: z
    .string()
    .min(1, 'Area name is required')
    .max(100, 'Area name must be 100 characters or less')
    .transform((v) => v.trim()),
  description: z
    .string()
    .max(500, 'Description must be 500 characters or less')
    .nullish()
    .transform((v) => v?.trim() || null),
  category: z
    .string()
    .max(50, 'Category must be 50 characters or less')
    .nullish()
    .transform((v) => v?.trim() || null),
  sortOrder: z.number().int().min(0).default(0),
  startTime: timeStringSchema,
  endTime: timeStringSchema,
});

export type CreateAreaInput = z.infer<typeof createAreaSchema>;

export const updateAreaSchema = z.object({
  name: z
    .string()
    .min(1, 'Area name is required')
    .max(100, 'Area name must be 100 characters or less')
    .transform((v) => v.trim())
    .optional(),
  description: z
    .string()
    .max(500, 'Description must be 500 characters or less')
    .nullish()
    .transform((v) => v?.trim() || null),
  category: z
    .string()
    .max(50, 'Category must be 50 characters or less')
    .nullish()
    .transform((v) => v?.trim() || null),
  sortOrder: z.number().int().min(0).optional(),
  startTime: timeStringSchema,
  endTime: timeStringSchema,
});

export type UpdateAreaInput = z.infer<typeof updateAreaSchema>;

export const setAreaCaptainSchema = z.object({
  areaId: z.string().min(1, 'Area ID is required'),
  sessionId: z.string().min(1, 'Session ID is required'),
  eventVolunteerId: z.string().min(1, 'Event volunteer ID is required'),
  forceAssigned: z.boolean().optional().default(false),
  acceptedDeadline: z.coerce.date().optional(),
});

export type SetAreaCaptainInput = z.infer<typeof setAreaCaptainSchema>;

export const removeAreaCaptainSchema = z.object({
  areaId: z.string().min(1, 'Area ID is required'),
  sessionId: z.string().min(1, 'Session ID is required'),
});

export type RemoveAreaCaptainInput = z.infer<typeof removeAreaCaptainSchema>;

export const acceptAreaCaptainSchema = z.object({
  areaCaptainId: z.string().min(1, 'AreaCaptain ID is required'),
});

export type AcceptAreaCaptainInput = z.infer<typeof acceptAreaCaptainSchema>;

export const declineAreaCaptainSchema = z.object({
  areaCaptainId: z.string().min(1, 'AreaCaptain ID is required'),
  reason: z
    .string()
    .max(500, 'Reason too long')
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
});

export type DeclineAreaCaptainInput = z.infer<typeof declineAreaCaptainSchema>;
