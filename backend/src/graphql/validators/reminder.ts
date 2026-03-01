/**
 * Reminder Confirmation Input Validators
 *
 * Zod schemas for validating reminder confirmation inputs.
 *
 * Schemas:
 *   - confirmShiftReminderSchema: shiftId (string)
 *   - confirmSessionReminderSchema: sessionId (string)
 *
 * Used by: ../resolvers/reminder.ts
 */
import { z } from 'zod';

export const confirmShiftReminderSchema = z.object({
  shiftId: z.string().min(1, 'Shift ID is required'),
});

export const confirmSessionReminderSchema = z.object({
  sessionId: z.string().min(1, 'Session ID is required'),
});

export type ConfirmShiftReminderInput = z.infer<typeof confirmShiftReminderSchema>;
export type ConfirmSessionReminderInput = z.infer<typeof confirmSessionReminderSchema>;
