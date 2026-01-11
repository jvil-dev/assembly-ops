/**
 * Message Validators
 *
 * Zod schemas for validating message-related GraphQL inputs.
 *
 * Schemas:
 *   - sendMessageSchema: Validate individual message input
 *   - sendDepartmentMessageSchema: Validate department broadcast input
 *   - sendBroadcastSchema: Validate event-wide broadcast input
 *   - messageFilterSchema: Validate message filter options
 */
import { z } from 'zod';

export const sendMessageSchema = z.object({
  volunteerId: z.string().min(1, 'Volunteer ID is required'),
  subject: z
    .string()
    .max(200, 'Subject too long')
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
  body: z
    .string()
    .transform((v: string) => v.trim())
    .pipe(z.string().min(1, 'Message body is required').max(5000, 'Message too long')),
});

export const sendDepartmentMessageSchema = z.object({
  departmentId: z.string().min(1, 'Department ID is required'),
  subject: z
    .string()
    .max(200, 'Subject too long')
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
  body: z
    .string()
    .transform((v: string) => v.trim())
    .pipe(z.string().min(1, 'Message body is required').max(5000, 'Message too long')),
});

export const sendBroadcastSchema = z.object({
  eventId: z.string().min(1, 'Event ID is required'),
  subject: z
    .string()
    .max(200, 'Subject too long')
    .nullish()
    .transform((v: string | null | undefined) => v?.trim() || null),
  body: z
    .string()
    .transform((v: string) => v.trim())
    .pipe(z.string().min(1, 'Message body is required').max(5000, 'Message too long')),
});

export const messageFilterSchema = z.object({
  isRead: z.boolean().optional(),
  senderId: z.string().optional(),
});

export type SendMessageInput = z.infer<typeof sendMessageSchema>;
export type SendDepartmentMessageInput = z.infer<typeof sendDepartmentMessageSchema>;
export type SendBroadcastInput = z.infer<typeof sendBroadcastSchema>;
export type MessageFilterInput = z.infer<typeof messageFilterSchema>;
