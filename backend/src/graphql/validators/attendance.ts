/**
 * Attendance Input Validators
 *
 * Zod schemas for validating attendance count inputs before processing.
 * Used for CO-24 reporting with section-based counting.
 *
 * Schemas:
 *   - submitAttendanceCountSchema: Record count for session/section
 *   - updateAttendanceCountSchema: Modify existing count
 *   - attendanceCountFilterSchema: Filter for queries
 *
 * Business Rules Enforced:
 *   - Session ID required for submit
 *   - Section name max 50 chars (optional, e.g., "A1", "Floor")
 *   - Count must be non-negative integer
 *   - Notes max 500 chars (optional)
 *
 * Used by: ../services/attendanceService.ts
 */
import { z } from 'zod';

export const submitAttendanceCountSchema = z.object({
  sessionId: z.string().min(1, 'Session ID is required'),
  section: z
    .string()
    .max(50, 'Section name too long')
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
  postId: z.string().min(1).optional(),
  count: z.number().int().min(0, 'Count must be non-negative'),
  notes: z
    .string()
    .max(500, 'Notes too long')
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
});

export const updateAttendanceCountSchema = z.object({
  count: z.number().int().min(0, 'Count must be non-negative').optional(),
  notes: z
    .string()
    .max(500, 'Notes too long')
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
});

export const attendanceCountFilterSchema = z.object({
  sessionId: z.string().optional(),
  eventId: z.string().optional(),
});

export type SubmitAttendanceCountInput = z.infer<typeof submitAttendanceCountSchema>;
export type UpdateAttendanceCountInput = z.infer<typeof updateAttendanceCountSchema>;
export type AttendanceCountFilter = z.infer<typeof attendanceCountFilterSchema>;
