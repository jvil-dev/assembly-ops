/**
 * Assignment Input Validators
 *
 * Zod schemas for validating schedule assignment inputs before processing.
 * Assignments link a Volunteer to a Post for a specific Session.
 *
 * Schemas:
 *   - createAssignmentSchema: Single assignment (volunteerId + postId + sessionId)
 *   - createAssignmentsSchema: Bulk assignments (array of assignments)
 *   - updateAssignmentSchema: Partial update (change post or session)
 *
 * Business Rules Enforced:
 *   - All IDs must be non-empty strings
 *   - Bulk create requires at least one assignment
 *   - Update fields are optional (patch-style)
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
});

export const createAssignmentsSchema = z.object({
  assignments: z.array(createAssignmentSchema).min(1, 'At least one assignment required'),
});

export const updateAssignmentSchema = z.object({
  postId: z.string().min(1, 'Post ID is required').optional(),
  sessionId: z.string().min(1, 'Session ID is required').optional(),
});

export type CreateAssignmentInput = z.infer<typeof createAssignmentSchema>;
export type CreateAssignmentsInput = z.infer<typeof createAssignmentsSchema>;
export type UpdateAssignmentInput = z.infer<typeof updateAssignmentSchema>;
