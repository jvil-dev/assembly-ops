/**
 * Message Resolvers
 *
 * GraphQL resolvers for bi-directional messaging operations.
 * Supports both admin and volunteer senders/recipients.
 *
 * Queries:
 *   - message: Get message by ID (any auth)
 *   - sentMessages: Get messages sent by admin
 *   - myMessages: Get inbox for any user
 *   - unreadMessageCount: Get unread count for any user
 *   - myConversations: Get conversation threads
 *   - conversationMessages: Get messages in a thread
 *   - searchMessages: Full-text search
 *
 * Mutations:
 *   - sendMessage: Send to individual (any user)
 *   - sendDepartmentMessage: Broadcast to department (admin)
 *   - sendBroadcast: Broadcast to event (event overseer)
 *   - sendMultiMessage: Send to multiple volunteers (admin)
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
 *   - Message.senderId: Computed from senderAdminId or senderVolId
 *   - Conversation.lastMessage: Most recent message in thread
 *   - Conversation.unreadCount: Unread messages for current user
 *   - ConversationParticipant.displayName: Computed from Admin or EventVolunteer
 */
import { Context } from '../context.js';
import { MessageService, SenderIdentity } from '../../services/messageService.js';
import { requireAdmin, requireAuth, requireEventAccess } from '../guards/auth.js';
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
  if (context.admin) {
    return { senderType: 'ADMIN' as MessageSenderType, senderId: context.admin.id };
  }
  if (context.volunteer) {
    return { senderType: 'VOLUNTEER' as MessageSenderType, senderId: context.volunteer.id };
  }
  throw new Error('You must be logged in');
}

const messageResolvers = {
  Query: {
    message: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAuth(context);
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
      const identity = resolveSenderIdentity(context);

      // If volunteer, verify they belong to this event
      if (context.volunteer && context.volunteer.eventId !== eventId) {
        throw new Error('You do not have access to this event');
      }
      // If admin, verify event access
      if (context.admin) {
        await requireEventAccess(context, eventId);
      }

      // Exclude self by ID only (not by name — different people can share a name)
      const excludeAdminIds = new Set<string>();
      const excludeVolunteerIds = new Set<string>();

      if (identity.senderType === 'ADMIN') {
        excludeAdminIds.add(identity.senderId);
      } else if (identity.senderType === 'VOLUNTEER') {
        excludeVolunteerIds.add(identity.senderId);

        // Also check legacy Volunteer table in case senderId is a legacy Volunteer.id
        const legacyVol = await context.prisma.volunteer.findUnique({
          where: { id: identity.senderId },
          select: { volunteerId: true },
        });
        if (legacyVol) {
          const matchingEv = await context.prisma.eventVolunteer.findFirst({
            where: { eventId, volunteerId: legacyVol.volunteerId },
            select: { id: true },
          });
          if (matchingEv) excludeVolunteerIds.add(matchingEv.id);
        }
      }

      // Fetch admins for this event
      const eventAdmins = await context.prisma.eventAdmin.findMany({
        where: { eventId },
        include: { admin: { select: { id: true, firstName: true, lastName: true } } },
      });

      // Fetch event volunteers
      const eventVolunteers = await context.prisma.eventVolunteer.findMany({
        where: { eventId },
        include: { volunteerProfile: { select: { id: true, firstName: true, lastName: true } } },
      });

      const participants: Array<{ id: string; displayName: string; isAdmin: boolean }> = [];

      for (const ea of eventAdmins) {
        if (excludeAdminIds.has(ea.admin.id)) continue;
        participants.push({
          id: ea.admin.id,
          displayName: `${ea.admin.firstName} ${ea.admin.lastName}`,
          isAdmin: true,
        });
      }

      for (const ev of eventVolunteers) {
        if (excludeVolunteerIds.has(ev.id)) continue;
        participants.push({
          id: ev.id,
          displayName: `${ev.volunteerProfile.firstName} ${ev.volunteerProfile.lastName}`,
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
      if (context.admin) {
        if (input.volunteerId) {
          eventId = await messageService.getVolunteerEventId(input.volunteerId);
        } else if (input.eventId) {
          eventId = input.eventId;
        } else {
          throw new Error('Event ID or volunteer ID is required');
        }
        await requireEventAccess(context, eventId);
      } else {
        // Volunteer sender — use their own eventId from context
        eventId = context.volunteer!.eventId;
      }

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
      await requireEventAccess(context, input.eventId, ['APP_ADMIN']);
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
      if (parent.senderAdminId) {
        const admin = (parent as Record<string, unknown>).senderAdmin as Record<string, string> | null;
        if (admin) return `${admin.firstName} ${admin.lastName}`;
        const fetched = await context.prisma.admin.findUnique({
          where: { id: parent.senderAdminId as string },
          select: { firstName: true, lastName: true },
        });
        return fetched ? `${fetched.firstName} ${fetched.lastName}` : 'Unknown';
      }
      if (parent.senderVolId) {
        const senderVol = parent.senderVol as Record<string, unknown> | null;
        if (senderVol) {
          const profile = senderVol.volunteerProfile as Record<string, string> | null;
          if (profile) return `${profile.firstName} ${profile.lastName}`;
        }
        const fetched = await context.prisma.eventVolunteer.findUnique({
          where: { id: parent.senderVolId as string },
          include: { volunteerProfile: true },
        });
        return fetched ? `${fetched.volunteerProfile.firstName} ${fetched.volunteerProfile.lastName}` : 'Unknown';
      }
      // Legacy fallback
      if (parent.senderId) {
        const sender = parent.sender as Record<string, string> | null;
        if (sender) return `${sender.firstName} ${sender.lastName}`;
        const fetched = await context.prisma.admin.findUnique({
          where: { id: parent.senderId as string },
          select: { firstName: true, lastName: true },
        });
        return fetched ? `${fetched.firstName} ${fetched.lastName}` : 'Overseer';
      }
      return null;
    },

    senderId: (parent: Record<string, unknown>) => {
      return parent.senderAdminId || parent.senderVolId || parent.senderId || null;
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
          senderAdmin: true,
          senderVol: { include: { volunteerProfile: true } },
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

      const senderField = identity.senderType === 'ADMIN' ? 'senderAdminId' : 'senderVolId';
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
  },

  ConversationParticipant: {
    displayName: async (parent: Record<string, unknown>, _args: unknown, context: Context) => {
      const type = parent.participantType as string;
      const id = parent.participantId as string;

      if (type === 'ADMIN') {
        const admin = await context.prisma.admin.findUnique({
          where: { id },
          select: { firstName: true, lastName: true },
        });
        return admin ? `${admin.firstName} ${admin.lastName}` : 'Unknown';
      }

      const ev = await context.prisma.eventVolunteer.findUnique({
        where: { id },
        include: { volunteerProfile: true },
      });
      return ev ? `${ev.volunteerProfile.firstName} ${ev.volunteerProfile.lastName}` : 'Unknown';
    },
  },
};

export default messageResolvers;
