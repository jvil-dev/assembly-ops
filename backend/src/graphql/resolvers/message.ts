/**
 * Message Resolvers
 *
 * GraphQL resolvers for bi-directional messaging operations.
 * Supports both overseer and volunteer senders/recipients.
 *
 * Queries:
 *   - message: Get message by ID (any auth)
 *   - sentMessages: Get messages sent by overseer
 *   - myMessages: Get inbox for any user
 *   - unreadMessageCount: Get unread count for any user
 *   - myConversations: Get conversation threads
 *   - conversationMessages: Get messages in a thread
 *   - searchMessages: Full-text search
 *
 * Mutations:
 *   - sendMessage: Send to individual (any user)
 *   - sendDepartmentMessage: Broadcast to department (overseer)
 *   - sendBroadcast: Broadcast to event (event overseer)
 *   - sendMultiMessage: Send to multiple volunteers (overseer)
 *   - startConversation: Create DM thread
 *   - sendConversationMessage: Reply in thread
 *   - markMessageRead: Mark message as read (any user)
 *   - markAllMessagesRead: Mark all as read (any user)
 *   - deleteMessage: Soft delete message (any user)
 *   - markConversationRead: Mark thread read
 *   - deleteConversation: Soft delete thread
 *
 * Type resolvers:
 *   - Message.senderName: Computed from senderAdmin or senderVol
 *   - Message.senderId: Computed from senderUserId or senderVolId
 *   - Conversation.lastMessage: Most recent message in thread
 *   - Conversation.unreadCount: Unread messages for current user
 *   - ConversationParticipant.displayName: Computed from User or EventVolunteer
 */
import { withFilter } from 'graphql-subscriptions';
import { Context } from '../context.js';
import { MessageService, SenderIdentity } from '../../services/messageService.js';
import { requireAdmin, requireAuth, requireEventAccess } from '../guards/auth.js';
import { AuthorizationError } from '../../utils/errors.js';
import { pubsub, MESSAGE_RECEIVED, CONVERSATION_MESSAGE_RECEIVED, UNREAD_COUNT_UPDATED } from '../pubsub.js';
import {
  SendMessageInput,
  SendDepartmentMessageInput,
  SendBroadcastInput,
  SendMultiMessageInput,
  StartConversationInput,
  SendConversationMessageInput,
  MessageFilterInput,
  SearchMessagesInput,
} from '../validators/message.js';
import { MessageSenderType } from '@prisma/client';

/**
 * Resolve the generic sender identity from auth context.
 * Works for both admin and volunteer tokens.
 */
function resolveSenderIdentity(context: Context): SenderIdentity {
  if (!context.user) throw new Error('You must be logged in');
  return { senderType: 'USER' as MessageSenderType, senderId: context.user.id };
}

const messageResolvers = {
  Query: {
    message: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAuth(context);
      const identity = resolveSenderIdentity(context);
      const messageService = new MessageService(context.prisma);
      const msg = await messageService.getMessage(id);
      if (!msg) return null;

      // Check ownership: sender, direct recipient, or broadcast recipient
      const isSender =
        (msg.senderUserId && msg.senderUserId === identity.senderId) ||
        (msg.senderVolId && msg.senderVolId === identity.senderId);
      const isRecipient = msg.recipientId === identity.senderId;
      const isBroadcast = msg.recipientType === 'EVENT' || msg.recipientType === 'DEPARTMENT';

      if (!isSender && !isRecipient && !isBroadcast) {
        throw new AuthorizationError('You do not have access to this message');
      }

      return msg;
    },

    sentMessages: async (
      _parent: unknown,
      { limit, offset }: { limit?: number; offset?: number },
      context: Context
    ) => {
      requireAdmin(context);
      const messageService = new MessageService(context.prisma);
      return messageService.getSentMessages(context.user!.id, limit ?? 50, offset ?? 0);
    },

    myMessages: async (
      _parent: unknown,
      { filter, limit, offset }: { filter?: MessageFilterInput; limit?: number; offset?: number },
      context: Context
    ) => {
      requireAuth(context);
      const identity = resolveSenderIdentity(context);
      const messageService = new MessageService(context.prisma);
      return messageService.getInboxMessages(identity, filter, limit ?? 50, offset ?? 0);
    },

    unreadMessageCount: async (_parent: unknown, _args: unknown, context: Context) => {
      requireAuth(context);
      const identity = resolveSenderIdentity(context);
      const messageService = new MessageService(context.prisma);
      return messageService.getUnreadCount(identity);
    },

    myConversations: async (
      _parent: unknown,
      { eventId, limit, offset }: { eventId: string; limit?: number; offset?: number },
      context: Context
    ) => {
      requireAuth(context);
      const identity = resolveSenderIdentity(context);
      const messageService = new MessageService(context.prisma);
      return messageService.getConversations(identity, eventId, limit ?? 50, offset ?? 0);
    },

    conversationMessages: async (
      _parent: unknown,
      { conversationId, limit, offset }: { conversationId: string; limit?: number; offset?: number },
      context: Context
    ) => {
      requireAuth(context);
      const identity = resolveSenderIdentity(context);
      const messageService = new MessageService(context.prisma);
      return messageService.getConversationMessages(
        conversationId,
        identity,
        limit ?? 50,
        offset ?? 0
      );
    },

    searchMessages: async (
      _parent: unknown,
      { eventId, query, limit, offset }: { eventId: string; query: string; limit?: number; offset?: number },
      context: Context
    ) => {
      requireAuth(context);
      const identity = resolveSenderIdentity(context);
      const messageService = new MessageService(context.prisma);
      return messageService.searchMessages(
        identity,
        { eventId, query } as SearchMessagesInput,
        limit ?? 50,
        offset ?? 0
      );
    },

    eventParticipants: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAuth(context);

      // Allow both event admins and event volunteers (not just admins)
      const [eventAdmin, eventVolunteer] = await Promise.all([
        context.prisma.eventAdmin.findUnique({
          where: { userId_eventId: { userId: context.user!.id, eventId } },
        }),
        context.prisma.eventVolunteer.findUnique({
          where: { userId_eventId: { userId: context.user!.id, eventId } },
        }),
      ]);
      if (!eventAdmin && !eventVolunteer) {
        throw new AuthorizationError('You do not have access to this event');
      }

      // Exclude self by user ID (not by name — different people can share a name)
      const currentUserId = context.user!.id;

      // Fetch admins and volunteers for this event in parallel
      const [eventAdmins, eventVolunteers] = await Promise.all([
        context.prisma.eventAdmin.findMany({
          where: { eventId },
          include: { user: { select: { id: true, firstName: true, lastName: true } } },
        }),
        context.prisma.eventVolunteer.findMany({
          where: { eventId },
          include: { user: { select: { id: true, firstName: true, lastName: true } } },
        }),
      ]);

      const participants: Array<{ id: string; displayName: string; isAdmin: boolean }> = [];

      for (const ea of eventAdmins) {
        if (ea.user.id === currentUserId) continue;
        participants.push({
          id: ea.user.id,
          displayName: `${ea.user.firstName} ${ea.user.lastName}`,
          isAdmin: true,
        });
      }

      for (const ev of eventVolunteers) {
        if (ev.user.id === currentUserId) continue;
        participants.push({
          id: ev.id,
          displayName: `${ev.user.firstName} ${ev.user.lastName}`,
          isAdmin: false,
        });
      }

      // Sort alphabetically by display name
      participants.sort((a, b) => a.displayName.localeCompare(b.displayName));

      return participants;
    },
  },

  Mutation: {
    sendMessage: async (
      _parent: unknown,
      { input }: { input: SendMessageInput },
      context: Context
    ) => {
      requireAuth(context);
      const identity = resolveSenderIdentity(context);
      const messageService = new MessageService(context.prisma);

      // Determine eventId for access control
      let eventId: string;
      if (input.volunteerId) {
        eventId = await messageService.getVolunteerEventId(input.volunteerId);
      } else if (input.eventId) {
        eventId = input.eventId;
      } else {
        throw new Error('Event ID or volunteer ID is required');
      }
      await requireEventAccess(context, eventId);

      return messageService.sendMessage(identity, input, eventId);
    },

    sendDepartmentMessage: async (
      _parent: unknown,
      { input }: { input: SendDepartmentMessageInput },
      context: Context
    ) => {
      requireAdmin(context);
      const identity = resolveSenderIdentity(context);
      const messageService = new MessageService(context.prisma);
      const eventId = await messageService.getDepartmentEventId(input.departmentId);
      await requireEventAccess(context, eventId);
      return messageService.sendDepartmentMessage(identity, input);
    },

    sendBroadcast: async (
      _parent: unknown,
      { input }: { input: SendBroadcastInput },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, input.eventId);
      const identity = resolveSenderIdentity(context);
      const messageService = new MessageService(context.prisma);
      return messageService.sendBroadcast(identity, input);
    },

    sendMultiMessage: async (
      _parent: unknown,
      { input }: { input: SendMultiMessageInput },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, input.eventId);
      const identity = resolveSenderIdentity(context);
      const messageService = new MessageService(context.prisma);
      return messageService.sendMultiMessage(identity, input);
    },

    startConversation: async (
      _parent: unknown,
      { input }: { input: StartConversationInput },
      context: Context
    ) => {
      requireAuth(context);
      const identity = resolveSenderIdentity(context);
      const messageService = new MessageService(context.prisma);
      return messageService.startConversation(identity, input);
    },

    sendConversationMessage: async (
      _parent: unknown,
      { input }: { input: SendConversationMessageInput },
      context: Context
    ) => {
      requireAuth(context);
      const identity = resolveSenderIdentity(context);
      const messageService = new MessageService(context.prisma);
      return messageService.sendConversationMessage(identity, input);
    },

    markMessageRead: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAuth(context);
      const identity = resolveSenderIdentity(context);
      const messageService = new MessageService(context.prisma);
      return messageService.markAsRead(id, identity);
    },

    markAllMessagesRead: async (
      _parent: unknown,
      { eventId }: { eventId?: string },
      context: Context
    ) => {
      requireAuth(context);
      const identity = resolveSenderIdentity(context);
      const messageService = new MessageService(context.prisma);
      const count = await messageService.markAllAsRead(identity, eventId);
      return { markedCount: count };
    },

    deleteMessage: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAuth(context);
      const identity = resolveSenderIdentity(context);
      const messageService = new MessageService(context.prisma);
      return messageService.softDeleteMessage(id, identity);
    },

    markConversationRead: async (
      _parent: unknown,
      { id }: { id: string },
      context: Context
    ) => {
      requireAuth(context);
      const identity = resolveSenderIdentity(context);
      const messageService = new MessageService(context.prisma);
      return messageService.markConversationRead(id, identity);
    },

    deleteConversation: async (
      _parent: unknown,
      { id }: { id: string },
      context: Context
    ) => {
      requireAuth(context);
      const identity = resolveSenderIdentity(context);
      const messageService = new MessageService(context.prisma);
      return messageService.deleteConversation(id, identity);
    },
  },

  // Type resolvers for computed fields
  Message: {
    senderName: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      // Try new sender fields first
      if (parent.senderUserId) {
        const admin = (parent as Record<string, unknown>).senderUser as Record<string, string> | null;
        if (admin) return `${admin.firstName} ${admin.lastName}`;
        const fetched = await context.prisma.user.findUnique({
          where: { id: parent.senderUserId as string },
          select: { firstName: true, lastName: true },
        });
        return fetched ? `${fetched.firstName} ${fetched.lastName}` : 'Unknown';
      }
      if (parent.senderVolId) {
        const senderVol = parent.senderVol as Record<string, unknown> | null;
        if (senderVol) {
          const profile = senderVol.user as Record<string, string> | null;
          if (profile) return `${profile.firstName} ${profile.lastName}`;
        }
        const fetched = await context.prisma.eventVolunteer.findUnique({
          where: { id: parent.senderVolId as string },
          include: { user: true },
        });
        return fetched ? `${fetched.user.firstName} ${fetched.user.lastName}` : 'Unknown';
      }
      // Legacy fallback
      if (parent.senderId) {
        const sender = parent.sender as Record<string, string> | null;
        if (sender) return `${sender.firstName} ${sender.lastName}`;
        const fetched = await context.prisma.user.findUnique({
          where: { id: parent.senderId as string },
          select: { firstName: true, lastName: true },
        });
        return fetched ? `${fetched.firstName} ${fetched.lastName}` : 'Overseer';
      }
      return null;
    },

    senderId: (parent: Record<string, unknown>) => {
      return parent.senderUserId || parent.senderVolId || parent.senderId || null;
    },

    recipientName: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      const recipientType = parent.recipientType as string;
      const recipientId = parent.recipientId as string | null;

      if (!recipientId) return null;

      switch (recipientType) {
        case 'VOLUNTEER': {
          const ev = await context.prisma.eventVolunteer.findUnique({
            where: { id: recipientId },
            include: { user: { select: { firstName: true, lastName: true } } },
          });
          return ev ? `${ev.user.firstName} ${ev.user.lastName}` : null;
        }
        case 'USER': {
          const user = await context.prisma.user.findUnique({
            where: { id: recipientId },
            select: { firstName: true, lastName: true },
          });
          return user ? `${user.firstName} ${user.lastName}` : null;
        }
        case 'DEPARTMENT': {
          const dept = await context.prisma.department.findUnique({
            where: { id: recipientId },
            select: { name: true },
          });
          return dept?.name ?? null;
        }
        case 'EVENT': {
          const event = await context.prisma.event.findUnique({
            where: { id: parent.eventId as string },
            select: { name: true },
          });
          return event?.name ?? null;
        }
        default:
          return null;
      }
    },

    conversation: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      if (parent.conversation) return parent.conversation;
      if (!parent.conversationId) return null;
      return context.prisma.conversation.findUnique({
        where: { id: parent.conversationId as string },
        include: { participants: true },
      });
    },
  },

  Conversation: {
    lastMessage: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      // If already loaded via include
      const messages = parent.messages as Array<Record<string, unknown>> | undefined;
      if (messages && messages.length > 0) return messages[0];
      return context.prisma.message.findFirst({
        where: { conversationId: parent.id as string },
        orderBy: { createdAt: 'desc' },
        include: {
          senderUser: true,
          senderVol: { include: { user: true } },
        },
      });
    },

    unreadCount: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      const identity = resolveSenderIdentity(context);
      const participant = await context.prisma.conversationParticipant.findFirst({
        where: {
          conversationId: parent.id as string,
          participantType: identity.senderType,
          participantId: identity.senderId,
        },
      });
      if (!participant) return 0;

      const senderField = identity.senderType === 'USER' ? 'senderUserId' : 'senderVolId';
      return context.prisma.message.count({
        where: {
          conversationId: parent.id as string,
          createdAt: { gt: participant.lastReadAt || new Date(0) },
          NOT: { [senderField]: identity.senderId },
        },
      });
    },

    participants: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      if (parent.participants) return parent.participants;
      return context.prisma.conversationParticipant.findMany({
        where: { conversationId: parent.id as string },
      });
    },

    departmentName: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      const departmentId = parent.departmentId as string | null;
      if (!departmentId) return null;
      // If department was already included via relation
      if (parent.department && typeof parent.department === 'object') {
        return (parent.department as Record<string, unknown>).name ?? null;
      }
      const dept = await context.prisma.department.findUnique({
        where: { id: departmentId },
        select: { name: true },
      });
      return dept?.name ?? null;
    },
  },

  Subscription: {
    messageReceived: {
      subscribe: withFilter(
        () => pubsub.asyncIterableIterator(MESSAGE_RECEIVED),
        (payload, variables, context) => {
          return (
            payload.messageReceived.recipientUserId === context.user?.id &&
            payload.messageReceived.eventId === variables.eventId
          );
        }
      ),
      resolve: (payload: Record<string, unknown>) => payload.messageReceived,
    },

    conversationMessageReceived: {
      subscribe: withFilter(
        () => pubsub.asyncIterableIterator(CONVERSATION_MESSAGE_RECEIVED),
        (payload, variables, context) => {
          return (
            payload.conversationMessageReceived.conversationId === variables.conversationId &&
            payload.conversationMessageReceived.recipientUserId === context.user?.id
          );
        }
      ),
      resolve: (payload: Record<string, unknown>) => payload.conversationMessageReceived,
    },

    unreadCountUpdated: {
      subscribe: withFilter(
        () => pubsub.asyncIterableIterator(UNREAD_COUNT_UPDATED),
        (payload, _variables, context) => {
          return payload.unreadCountUpdated.userId === context.user?.id;
        }
      ),
      resolve: (payload: Record<string, unknown>) => (payload.unreadCountUpdated as Record<string, unknown>).count,
    },
  },

  ConversationParticipant: {
    displayName: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      const type = parent.participantType as string;
      const id = parent.participantId as string;

      if (type === 'USER') {
        const admin = await context.prisma.user.findUnique({
          where: { id },
          select: { firstName: true, lastName: true },
        });
        return admin ? `${admin.firstName} ${admin.lastName}` : 'Unknown';
      }

      const ev = await context.prisma.eventVolunteer.findUnique({
        where: { id },
        include: { user: true },
      });
      return ev ? `${ev.user.firstName} ${ev.user.lastName}` : 'Unknown';
    },

    phone: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      const type = parent.participantType as string;
      const id = parent.participantId as string;

      if (type === 'USER') {
        const user = await context.prisma.user.findUnique({
          where: { id },
          select: { phone: true },
        });
        return user?.phone ?? null;
      }

      const ev = await context.prisma.eventVolunteer.findUnique({
        where: { id },
        include: { user: { select: { phone: true } } },
      });
      return ev?.user.phone ?? null;
    },

    congregation: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      const type = parent.participantType as string;
      const id = parent.participantId as string;

      if (type === 'USER') {
        const user = await context.prisma.user.findUnique({
          where: { id },
          select: { congregation: true },
        });
        return user?.congregation ?? null;
      }

      const ev = await context.prisma.eventVolunteer.findUnique({
        where: { id },
        include: { user: { select: { congregation: true } } },
      });
      return ev?.user.congregation ?? null;
    },
  },
};

export default messageResolvers;
