/**
 * Assignment Input Validators
 *
 * Zod schemas for validating schedule assignment inputs before processing.
 * Includes acceptance workflow, captain role, and force-assign schemas.
 *
 * Schemas:
 *   - createAssignmentSchema: Single assignment (volunteerId + postId + sessionId)
 *   - createAssignmentsSchema: Bulk assignments (array of assignments)
 *   - updateAssignmentSchema: Partial update (change post or session)
 *   - acceptAssignmentSchema: Accept a pending assignment
 *   - declineAssignmentSchema: Decline with optional reason
 *   - forceAssignmentSchema: Admin force-assign (bypasses acceptance)
 *   - setCaptainSchema: Designate assignment as captain
 *   - setCanCountSchema: Designate assignment as counter
 *   - captainCheckInSchema: Captain checks in group member
 *   - pendingAssignmentsFilterSchema: Filter for pending/declined queries
 *
 * Business Rules Enforced:
 *   - All IDs must be non-empty strings
 *   - Decline reason max 500 chars (optional)
 *   - Notes max 500 chars (optional)
 *   - Bulk create requires at least one assignment
 *
 * Note: Cross-entity validation (same event, capacity limits, conflict detection)
 * is handled in AssignmentService, not here.
 *
 * Used by: ../services/assignmentService.ts
 */
import { z } from 'zod';

export const createAssignmentSchema = z.object({
  volunteerId: z.string().min(1, 'Volunteer ID is required'),
  postId: z.string().min(1, 'Post ID is required'),
  sessionId: z.string().min(1, 'Session ID is required'),
  shiftId: z.string().min(1).nullish().transform((v: string | null | undefined) => v || null),
  canCount: z.boolean().optional().default(false),
});

export const createAssignmentsSchema = z.object({
  assignments: z.array(createAssignmentSchema).min(1, 'At least one assignment required'),
});

export const updateAssignmentSchema = z.object({
  postId: z.string().min(1, 'Post ID is required').optional(),
  sessionId: z.string().min(1, 'Session ID is required').optional(),
  canCount: z.boolean().optional(),
});

export const acceptAssignmentSchema = z.object({
  assignmentId: z.string().min(1, 'Assignment ID is required'),
});

export const declineAssignmentSchema = z.object({
  assignmentId: z.string().min(1, 'Assignment ID is required'),
  reason: z
    .string()
    .max(500, 'Reason too long')
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
});

export const forceAssignmentSchema = z.object({
  volunteerId: z.string().min(1, 'Volunteer ID is required'),
  postId: z.string().min(1, 'Post ID is required'),
  sessionId: z.string().min(1, 'Session ID is required'),
  shiftId: z.string().min(1).nullish().transform((v: string | null | undefined) => v || null),
  isCaptain: z.boolean().optional().default(false),
  canCount: z.boolean().optional().default(false),
});

export const setCaptainSchema = z.object({
  assignmentId: z.string().min(1, 'Assignment ID is required'),
  isCaptain: z.boolean(),
});

export const setCanCountSchema = z.object({
  assignmentId: z.string().min(1, 'Assignment ID is required'),
  canCount: z.boolean(),
});

export const captainCheckInSchema = z.object({
  assignmentId: z.string().min(1, 'Assignment ID is required'),
  notes: z
    .string()
    .max(500, 'Notes too long')
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
});

export const pendingAssignmentsFilterSchema = z.object({
  eventId: z.string().optional(),
  departmentId: z.string().optional(),
  status: z.enum(['PENDING', 'ACCEPTED', 'DECLINED', 'AUTO_DECLINED']).optional(),
});

export type CreateAssignmentInput = z.infer<typeof createAssignmentSchema>;
export type CreateAssignmentsInput = z.infer<typeof createAssignmentsSchema>;
export type UpdateAssignmentInput = z.infer<typeof updateAssignmentSchema>;
export type AcceptAssignmentInput = z.infer<typeof acceptAssignmentSchema>;
export type DeclineAssignmentInput = z.infer<typeof declineAssignmentSchema>;
export type ForceAssignmentInput = z.infer<typeof forceAssignmentSchema>;
export type SetCaptainInput = z.infer<typeof setCaptainSchema>;
export type SetCanCountInput = z.infer<typeof setCanCountSchema>;
export type CaptainCheckInInput = z.infer<typeof captainCheckInSchema>;
export type PendingAssignmentsFilter = z.infer<typeof pendingAssignmentsFilterSchema>;
