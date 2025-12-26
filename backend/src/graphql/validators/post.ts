/**
 * Post Validators (Zod Schemas)
 *
 * Runtime validation for post-related inputs.
 * Posts are physical locations/positions within a department (e.g., "Gate A", "Main Entrance").
 *
 * Schemas:
 *   - createPostSchema: Single post creation (name, description, location, capacity)
 *   - createPostsSchema: Bulk post creation (departmentId + array of posts)
 *   - updatePostSchema: Partial update (name, description, location, capacity - all optional)
 *
 * Fields:
 *   - name: Required on create, max 100 chars
 *   - description: Optional, describes the post's purpose
 *   - location: Optional, physical location details
 *   - capacity: How many volunteers needed (default 1 on create)
 *
 * Exports:
 *   - CreatePostInput, CreatePostsInput, UpdatePostInput (TypeScript types)
 *
 * Used by: Post service
 */
import { z } from 'zod';

export const createPostSchema = z.object({
  name: z
    .string()
    .min(1, 'Post name is required')
    .max(100, 'Post name too long')
    .transform((v: string) => v.trim()),
  description: z
    .string()
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
  location: z
    .string()
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
  capacity: z.number().int().min(1, 'Capacity must be at least 1').default(1),
});

export const createPostsSchema = z.object({
  departmentId: z.string().min(1, 'Department ID is required'),
  posts: z.array(createPostSchema).min(1, 'At least one post required'),
});

export const updatePostSchema = z.object({
  name: z
    .string()
    .min(1, 'Post name is required')
    .max(100, 'Post name is too long')
    .transform((v: string) => v.trim())
    .optional(),
  description: z
    .string()
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
  location: z
    .string()
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
  capacity: z.number().int().min(1, 'Capacity must be at least 1').optional(),
});

export type CreatePostInput = z.infer<typeof createPostSchema>;
export type CreatePostsInput = z.infer<typeof createPostsSchema>;
export type UpdatePostInput = z.infer<typeof updatePostSchema>;
