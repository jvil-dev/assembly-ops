/**
 * Message Resolvers
 *
 * GraphQL resolvers for messaging operations.
 *
 * Queries:
 *   - message: Get message by ID (admin only)
 *   - sentMessages: Get messages sent by admin
 *   - myMessages: Get messages for logged-in volunteer
 *   - unreadMessageCount: Get unread count for volunteer
 *
 * Mutations:
 *   - sendMessage: Send to individual volunteer (admin)
 *   - sendDepartmentMessage: Broadcast to department (admin)
 *   - sendBroadcast: Broadcast to event (event overseer only)
 *   - markMessageRead: Mark message as read (volunteer)
 *   - markAllMessagesRead: Mark all as read (volunteer)
 *   - deleteMessage: Delete a message (admin)
 */
import { Context } from '../context.js';
import { MessageService } from '../../services/messageService.js';
import { requireAdmin, requireVolunteer, requireEventAccess } from '../guards/auth.js';
import {
  SendMessageInput,
  SendDepartmentMessageInput,
  SendBroadcastInput,
  MessageFilterInput,
} from '../validators/message.js';

const messageResolvers = {
  Query: {
    message: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAdmin(context);
      const messageService = new MessageService(context.prisma);
      return messageService.getMessage(id);
    },

    sentMessages: async (
      _parent: unknown,
      { limit, offset }: { limit?: number; offset?: number },
      context: Context
    ) => {
      requireAdmin(context);
      const messageService = new MessageService(context.prisma);
      return messageService.getSentMessages(context.admin.id, limit ?? 50, offset ?? 0);
    },

    myMessages: async (
      _parent: unknown,
      { filter, limit, offset }: { filter?: MessageFilterInput; limit?: number; offset?: number },
      context: Context
    ) => {
      requireVolunteer(context);
      const messageService = new MessageService(context.prisma);
      return messageService.getVolunteerMessages(
        context.volunteer.id,
        filter,
        limit ?? 50,
        offset ?? 0
      );
    },

    unreadMessageCount: async (_parent: unknown, _args: unknown, context: Context) => {
      requireVolunteer(context);
      const messageService = new MessageService(context.prisma);
      return messageService.getUnreadCount(context.volunteer.id);
    },
  },

  Mutation: {
    sendMessage: async (
      _parent: unknown,
      { input }: { input: SendMessageInput },
      context: Context
    ) => {
      requireAdmin(context);

      const messageService = new MessageService(context.prisma);
      const eventId = await messageService.getVolunteerEventId(input.volunteerId);
      await requireEventAccess(context, eventId);

      return messageService.sendMessage(context.admin.id, input);
    },

    sendDepartmentMessage: async (
      _parent: unknown,
      { input }: { input: SendDepartmentMessageInput },
      context: Context
    ) => {
      requireAdmin(context);

      const messageService = new MessageService(context.prisma);
      const eventId = await messageService.getDepartmentEventId(input.departmentId);
      await requireEventAccess(context, eventId);

      return messageService.sendDepartmentMessage(context.admin.id, input);
    },

    sendBroadcast: async (
      _parent: unknown,
      { input }: { input: SendBroadcastInput },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, input.eventId, ['EVENT_OVERSEER']);

      const messageService = new MessageService(context.prisma);
      return messageService.sendBroadcast(context.admin.id, input);
    },

    deleteMessage: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAdmin(context);

      const messageService = new MessageService(context.prisma);
      const message = await messageService.getMessage(id);

      // Check if message exists before attempting to delete
      if (!message) {
        throw new Error('Message not found');
      }

      // All messages should have an event association; require event access for deletion
      if (message.event?.id) {
        await requireEventAccess(context, message.event.id);
      }

      return messageService.deleteMessage(id);
    },

    markMessageRead: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireVolunteer(context);
      const messageService = new MessageService(context.prisma);
      return messageService.markAsRead(id, context.volunteer.id);
    },

    markAllMessagesRead: async (_parent: unknown, _args: unknown, context: Context) => {
      requireVolunteer(context);
      const messageService = new MessageService(context.prisma);
      const count = await messageService.markAllAsRead(context.volunteer.id);
      return { markedCount: count };
    },
  },
};

export default messageResolvers;
