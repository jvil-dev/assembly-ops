/**
 * Captain Scheduling Validators
 *
 * Zod schemas for captain-specific scheduling inputs.
 *
 * Used by: ../resolvers/captainScheduling.ts
 */
import { z } from 'zod';

export const captainCreateAssignmentSchema = z.object({
  eventId: z.string().min(1),
  eventVolunteerId: z.string().min(1),
  postId: z.string().min(1),
  sessionId: z.string().min(1),
  shiftId: z.string().min(1).nullish().transform(v => v ?? undefined),
  canCount: z.boolean().optional().default(false),
});
export type CaptainCreateAssignmentInput = z.infer<typeof captainCreateAssignmentSchema>;

export const captainSwapSchema = z.object({
  assignmentId: z.string().min(1),
  newEventVolunteerId: z.string().min(1),
});
export type CaptainSwapInput = z.infer<typeof captainSwapSchema>;

export const captainCreateShiftSchema = z.object({
  eventId: z.string().min(1),
  sessionId: z.string().min(1),
  postId: z.string().min(1),
  startTime: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/, 'Must be HH:MM format'),
  endTime: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/, 'Must be HH:MM format'),
});
export type CaptainCreateShiftInput = z.infer<typeof captainCreateShiftSchema>;

export const captainUpdateShiftSchema = z.object({
  eventId: z.string().min(1),
  startTime: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/, 'Must be HH:MM format').optional(),
  endTime: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/, 'Must be HH:MM format').optional(),
});
export type CaptainUpdateShiftInput = z.infer<typeof captainUpdateShiftSchema>;
