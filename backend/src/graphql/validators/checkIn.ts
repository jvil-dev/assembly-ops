/**
 * Check-In Validators (Zod Schemas)
 *
 * Runtime validation for check-in and attendance inputs.
 *
 * Schemas:
 *   - checkInSchema: Volunteer check-in (assignmentId)
 *   - checkOutSchema: Volunteer check-out (assignmentId)
 *   - adminCheckInSchema: Admin check-in on behalf of volunteer (assignmentId, notes?)
 *   - markNoShowSchema: Mark volunteer as no-show (assignmentId, notes?)
 *   - recordAttendanceSchema: Record audience count (sessionId, count, notes?)
 *   - updateAttendanceSchema: Update audience count (count?, notes?)
 *
 * Transformations:
 *   - notes: trimmed, null if empty
 *
 * Constraints:
 *   - notes: max 500 characters
 *   - count: non-negative integer
 *
 * Used by: ../../services/checkInService.ts, ../../services/attendanceService.ts
 */
import { z } from 'zod';

export const checkInSchema = z.object({
  assignmentId: z.string().min(1, 'Assignment ID is required'),
});

export const checkOutSchema = z.object({
  assignmentId: z.string().min(1, 'Assignment ID is required'),
});

export const adminCheckInSchema = z.object({
  assignmentId: z.string().min(1, 'Assignment ID is required'),
  notes: z
    .string()
    .max(500, 'Notes too long')
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
});

export const markNoShowSchema = z.object({
  assignmentId: z.string().min(1, 'Assignment ID is required'),
  notes: z
    .string()
    .max(500, 'Notes too long')
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
});

export const recordAttendanceSchema = z.object({
  sessionId: z.string().min(1, 'Session ID is required'),
  count: z.number().int().min(0, 'Count must be non-negative'),
  notes: z
    .string()
    .max(500, 'Notes too long')
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
});

export const updateAttendanceSchema = z.object({
  count: z.number().int().min(0, 'Count must be non-negative').optional(),
  notes: z
    .string()
    .max(500, 'Notes too long')
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
});

export type CheckInInput = z.infer<typeof checkInSchema>;
export type CheckOutInput = z.infer<typeof checkOutSchema>;
export type AdminCheckInInput = z.infer<typeof adminCheckInSchema>;
export type MarkNoShowInput = z.infer<typeof markNoShowSchema>;
export type RecordAttendanceInput = z.infer<typeof recordAttendanceSchema>;
export type UpdateAttendanceInput = z.infer<typeof updateAttendanceSchema>;
