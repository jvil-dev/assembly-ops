/**
 * Walk-Through Completion Input Validators
 *
 * Zod schemas for validating walk-through completion inputs.
 *
 * Schemas:
 *   - submitWalkThroughCompletionSchema: Validate eventId, sessionId, itemCount, notes
 *
 * Used by: ../../services/walkThroughService.ts
 */
import { z } from 'zod';

export const submitWalkThroughCompletionSchema = z.object({
  eventId: z.string().min(1),
  sessionId: z.string().min(1),
  itemCount: z.number().int().positive(),
  notes: z.string().max(2000).optional(),
});

export type SubmitWalkThroughCompletionInput = z.infer<typeof submitWalkThroughCompletionSchema>;
