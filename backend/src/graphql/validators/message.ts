/**
 * Message Validators
 *
 * Zod schemas for validating message-related GraphQL inputs.
 *
 * Schemas:
 *   - sendMessageSchema: Validate individual message input (supports bi-directional)
 *   - sendDepartmentMessageSchema: Validate department broadcast input
 *   - sendBroadcastSchema: Validate event-wide broadcast input
 *   - messageFilterSchema: Validate message filter options
 *   - startConversationSchema: Validate new conversation thread input
 *   - sendConversationMessageSchema: Validate reply in conversation thread
 *   - sendMultiMessageSchema: Validate multi-recipient message input
 *   - searchMessagesSchema: Validate message search input
 */
import { z } from 'zod';

// Reusable field schemas
const subjectField = z
  .string()
  .max(200, 'Subject too long')
  .nullish()
  .transform((v: string | null | undefined) => v?.trim() || null);

const bodyField = z
  .string()
  .transform((v: string) => v.trim())
  .pipe(z.string().min(1, 'Message body is required').max(5000, 'Message too long'));

const messageSenderType = z.enum(['USER', 'VOLUNTEER']);

// Existing schemas (updated for bi-directional support)
export const sendMessageSchema = z.object({
  volunteerId: z.string().min(1).optional(),
  recipientType: messageSenderType.optional(),
  recipientId: z.string().min(1).optional(),
  eventId: z.string().min(1).optional(),
  subject: subjectField,
  body: bodyField,
});

export const sendDepartmentMessageSchema = z.object({
  departmentId: z.string().min(1, 'Department ID is required'),
  subject: subjectField,
  body: bodyField,
});

export const sendBroadcastSchema = z.object({
  eventId: z.string().min(1, 'Event ID is required'),
  subject: subjectField,
  body: bodyField,
});

export const messageFilterSchema = z.object({
  isRead: z.boolean().optional(),
  senderId: z.string().optional(),
  senderType: messageSenderType.optional(),
  recipientType: z.enum(['VOLUNTEER', 'DEPARTMENT', 'EVENT', 'USER']).optional(),
  search: z.string().max(200).optional(),
});

// New schemas for conversations
export const startConversationSchema = z.object({
  eventId: z.string().min(1, 'Event ID is required'),
  recipientType: messageSenderType,
  recipientId: z.string().min(1, 'Recipient ID is required'),
  subject: subjectField,
  body: bodyField,
});

export const sendConversationMessageSchema = z.object({
  conversationId: z.string().min(1, 'Conversation ID is required'),
  body: bodyField,
});

export const sendMultiMessageSchema = z.object({
  volunteerIds: z.array(z.string().min(1)).min(1, 'At least one volunteer required').max(100, 'Maximum 100 recipients'),
  subject: subjectField,
  body: bodyField,
  eventId: z.string().min(1, 'Event ID is required'),
});

export const searchMessagesSchema = z.object({
  eventId: z.string().min(1, 'Event ID is required'),
  query: z.string().min(1, 'Search query is required').max(200, 'Search query too long'),
});

// Type exports
export type SendMessageInput = z.infer<typeof sendMessageSchema>;
export type SendDepartmentMessageInput = z.infer<typeof sendDepartmentMessageSchema>;
export type SendBroadcastInput = z.infer<typeof sendBroadcastSchema>;
export type MessageFilterInput = z.infer<typeof messageFilterSchema>;
export type StartConversationInput = z.infer<typeof startConversationSchema>;
export type SendConversationMessageInput = z.infer<typeof sendConversationMessageSchema>;
export type SendMultiMessageInput = z.infer<typeof sendMultiMessageSchema>;
export type SearchMessagesInput = z.infer<typeof searchMessagesSchema>;
