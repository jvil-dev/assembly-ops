/**
 * Post Session Status Input Validators
 *
 * Zod schemas for validating seating section status inputs.
 *
 * Schemas:
 *   - updatePostSessionStatusSchema: Validate postId, sessionId, status
 *
 * Used by: ../../services/postSessionStatusService.ts
 */
import { z } from 'zod';

export const updatePostSessionStatusSchema = z.object({
  postId: z.string().min(1),
  sessionId: z.string().min(1),
  status: z.enum(['OPEN', 'FILLING', 'FULL']),
});

export type UpdatePostSessionStatusInput = z.infer<typeof updatePostSessionStatusSchema>;
