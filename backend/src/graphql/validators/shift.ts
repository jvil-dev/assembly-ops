/**
 * Shift Input Validators
 *
 * Zod schemas for validating shift inputs before processing.
 * Shift times are free-form (not constrained to session program times)
 * since departments like Attendant/Parking start duty before the program.
 *
 * Schemas:
 *   - createShiftSchema: sessionId + postId + startTime (HH:MM) + endTime (HH:MM)
 *   - updateShiftSchema: Partial update (startTime/endTime optional)
 *
 * Business Rules Enforced:
 *   - Time format: HH:MM (24-hour)
 *   - endTime must be after startTime (validated in service, not here — times are strings)
 *   - Name is auto-generated from the time range
 *
 * Used by: ../services/shiftService.ts
 */
import { z } from 'zod';

const timePattern = /^([01]\d|2[0-3]):([0-5]\d)$/;

export const createShiftSchema = z.object({
  sessionId: z.string().min(1, 'Session ID is required'),
  postId: z.string().min(1, 'Post ID is required'),
  startTime: z.string().regex(timePattern, 'Start time must be in HH:MM format'),
  endTime: z.string().regex(timePattern, 'End time must be in HH:MM format'),
});

export const updateShiftSchema = z.object({
  startTime: z.string().regex(timePattern, 'Start time must be in HH:MM format').optional(),
  endTime: z.string().regex(timePattern, 'End time must be in HH:MM format').optional(),
});

export type CreateShiftInput = z.infer<typeof createShiftSchema>;
export type UpdateShiftInput = z.infer<typeof updateShiftSchema>;
