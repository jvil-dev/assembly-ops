/**
 * Event Note Validators
 *
 * Zod schemas for validating event note GraphQL inputs.
 *
 * Schemas:
 *   - createEventNoteSchema: Validate note creation input
 *   - updateEventNoteSchema: Validate note update input
 */
import { z } from 'zod';

export const createEventNoteSchema = z.object({
  departmentId: z.string().min(1, 'Department ID is required'),
  title: z
    .string()
    .max(200, 'Title is too long')
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
  body: z
    .string()
    .transform((v: string) => v.trim())
    .pipe(z.string().min(1, 'Note body is required').max(5000, 'Note too long')),
});

export const updateEventNoteSchema = z.object({
  title: z
    .string()
    .max(200, 'Title too long')
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
  body: z
    .string()
    .transform((v: string) => v.trim())
    .pipe(z.string().min(1, 'Note body is required').max(5000, 'Note too long'))
    .optional(),
});

export type CreateEventNoteInput = z.infer<typeof createEventNoteSchema>;
export type UpdateEventNoteInput = z.infer<typeof updateEventNoteSchema>;
