/**
 * Session Validators (Zod Schemas)
 *
 * Runtime validation for session-related inputs.
 * Sessions are time blocks during an event (e.g., "Friday Morning", "Saturday Afternoon").
 * They are event-wide — all departments share the same sessions.
 *
 * Schemas:
 *   - createSessionSchema: Single session creation
 *   - createSessionsSchema: Bulk session creation (eventId + array of sessions)
 *   - updateSessionSchema: Partial update (patch-style, only send fields being changed)
 *
 * Fields:
 *   - name: Required, max 100 chars (e.g., "Friday Morning Session")
 *   - date: Required, coerced to Date object (accepts string or Date)
 *   - startTime: Required, 24-hour format "HH:MM" (e.g., "09:00")
 *   - endTime: Required, 24-hour format "HH:MM" (e.g., "12:00")
 *
 * Time Format:
 *   Uses regex /^([01]\d|2[0-3]):([0-5]\d)$/ to validate 24-hour time.
 *   Valid: "09:00", "14:30", "23:59"
 *   Invalid: "9:00", "25:00", "12:60"
 *
 * Exports:
 *   - CreateSessionInput, CreateSessionsInput, UpdateSessionInput (TypeScript types)
 *
 * Used by: Session service
 */
import { z } from 'zod';

export const createSessionSchema = z.object({
  name: z
    .string()
    .min(1, 'Session name is required')
    .max(100, 'Session name too long')
    .transform((v: string) => v.trim()),
  date: z.coerce.date(),
  startTime: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/, 'Invalid time format (HH:MM)'),
  endTime: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/, 'Invalid time format (HH:MM)'),
});

export const createSessionsSchema = z.object({
  eventId: z.string().min(1, 'Event ID is required'),
  sessions: z.array(createSessionSchema).min(1, 'At least one session required'),
});

export const updateSessionSchema = z.object({
  name: z
    .string()
    .min(1, 'Session name is required')
    .max(100, 'Session name too long')
    .transform((v: string) => v.trim())
    .optional(),
  date: z.coerce.date().optional(),
  startTime: z
    .string()
    .regex(/^([01]\d|2[0-3]):([0-5]\d)$/, 'Invalid time format (HH:MM)')
    .optional(),
  endTime: z
    .string()
    .regex(/^([01]\d|2[0-3]):([0-5]\d)$/, 'Invalid time format (HH:MM)')
    .optional(),
});

export type CreateSessionInput = z.infer<typeof createSessionSchema>;
export type CreateSessionsInput = z.infer<typeof createSessionsSchema>;
export type UpdateSessionInput = z.infer<typeof updateSessionSchema>;
