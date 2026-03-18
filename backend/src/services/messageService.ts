/**
 * Message Service
 *
 * Business logic for bi-directional messaging between overseers, volunteers,
 * and conversation threads.
 *
 * Existing methods (updated for dual-auth):
 *   - sendMessage: Send to individual (overseer or volunteer sender)
 *   - sendDepartmentMessage: Broadcast to department (overseer only)
 *   - sendBroadcast: Broadcast to event (overseer only)
 *   - getInboxMessages: Get messages for any user (was getVolunteerMessages)
 *   - getUnreadCount: Get unread count for any user
 *   - markAsRead: Mark single message as read (any user)
 *   - markAllAsRead: Mark all as read (any user)
 *   - getMessage: Get message by ID
 *   - getSentMessages: Get sent messages (overseer)
 *   - softDeleteMessage: Soft delete (was hard delete)
 *
 * New methods:
 *   - startConversation: Create DM thread between two users
 *   - sendConversationMessage: Reply in a thread
 *   - getConversations: List user's conversations
 *   - getConversationMessages: Get messages in a thread
 *   - markConversationRead: Mark thread read for user
 *   - deleteConversation: Soft delete thread for user
 *   - sendMultiMessage: Send to multiple volunteers at once
 *   - searchMessages: Full-text search on subject + body
 */
import { Prisma, PrismaClient, Message, MessageSenderType, RecipientType, ConversationType } from '@prisma/client';
import { NotFoundError, ValidationError, AuthorizationError } from '../utils/errors.js';
import { pubsub, MESSAGE_RECEIVED, CONVERSATION_MESSAGE_RECEIVED, UNREAD_COUNT_UPDATED } from '../graphql/pubsub.js';
import { NotificationService } from './notificationService.js';
import {
  sendMessageSchema,
  sendDepartmentMessageSchema,
  sendBroadcastSchema,
  startConversationSchema,
  sendConversationMessageSchema,
  sendMultiMessageSchema,
  searchMessagesSchema,
  SendMessageInput,
  SendDepartmentMessageInput,
  SendBroadcastInput,
  StartConversationInput,
  SendConversationMessageInput,
  SendMultiMessageInput,
  SearchMessagesInput,
  MessageFilterInput,
} from '../graphql/validators/message.js';

/** Sender identity resolved from auth context */
export interface SenderIdentity {
  senderType: MessageSenderType;
  senderId: string;
}

export class MessageService {
  private notificationService: NotificationService;

  constructor(private prisma: PrismaClient) {
    this.notificationService = new NotificationService(prisma);
  }

  // ─── Existing Methods (Updated for Dual-Auth) ───────────────────────

  /**
   * Send message to individual volunteer (now supports any sender type)
   */
  async sendMessage(
    sender: SenderIdentity,
    input: SendMessageInput,
    eventId: string
  ): Promise<Message> {
    const result = sendMessageSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { subject, body } = result.data;

    // Support both old (volunteerId) and new (recipientType + recipientId) formats
    const targetVolunteerId = result.data.volunteerId;
    const recipientType = result.data.recipientType;
    const recipientId = result.data.recipientId;

    // Prevent self-messaging
    if (
      recipientType &&
      recipientId &&
      sender.senderType === recipientType &&
      sender.senderId === recipientId
    ) {
      throw new ValidationError('You cannot send a message to yourself');
    }

    if (recipientType === 'USER' && recipientId) {
      // Sending to an admin — create a message with ADMIN recipientType
      const user = await this.prisma.user.findUnique({
        where: { id: recipientId },
        select: { id: true },
      });
      if (!user) throw new NotFoundError('User');

      const msg = await this.prisma.message.create({
        data: {
          subject,
          body,
          recipientType: RecipientType.USER,
          recipientId: recipientId,
          eventId,
          senderType: sender.senderType,
          senderUserId: sender.senderType === 'USER' ? sender.senderId : null,
          senderVolId: sender.senderType === 'VOLUNTEER' ? sender.senderId : null,
        },
        include: { senderUser: true, event: true },
      });

      this.publishMessageEvents(msg, recipientId, eventId);
      return msg;
    }

    // Sending to a volunteer — use volunteerId (legacy) or recipientId (new)
    const volId = targetVolunteerId || recipientId;
    if (!volId) throw new ValidationError('Volunteer ID or recipient ID is required');

    // Verify eventVolunteer exists
    const eventVolunteer = await this.prisma.eventVolunteer.findUnique({
      where: { id: volId },
      select: { id: true, eventId: true, userId: true },
    });

    if (!eventVolunteer) throw new NotFoundError('EventVolunteer');

    const msg = await this.prisma.message.create({
      data: {
        subject,
        body,
        recipientType: RecipientType.VOLUNTEER,
        recipientId: volId,
        eventId: eventVolunteer.eventId,
        senderType: sender.senderType,
        senderUserId: sender.senderType === 'USER' ? sender.senderId : null,
        senderVolId: sender.senderType === 'VOLUNTEER' ? sender.senderId : null,
        eventVolunteerId: volId,
      },
      include: { senderUser: true, event: true },
    });

    this.publishMessageEvents(msg, eventVolunteer.userId, eventVolunteer.eventId);
    return msg;
  }

  /**
   * Send message to all volunteers in a department (admin only).
   * Uses a per-scope conversation thread so subsequent broadcasts land in the same thread.
   */
  async sendDepartmentMessage(
    sender: SenderIdentity,
    input: SendDepartmentMessageInput
  ) {
    const result = sendDepartmentMessageSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { departmentId, subject, body } = result.data;

    const department = await this.prisma.department.findUnique({
      where: { id: departmentId },
      include: {
        eventVolunteers: { select: { id: true, userId: true } },
        event: { select: { id: true } },
      },
    });

    if (!department) throw new NotFoundError('Department');
    const eventId = department.event.id;

    // Find or create broadcast conversation for this department
    let conversation = await this.prisma.conversation.findFirst({
      where: { type: ConversationType.DEPARTMENT_BROADCAST, eventId, departmentId },
      include: { participants: true },
    });

    if (!conversation) {
      conversation = await this.prisma.conversation.create({
        data: {
          eventId,
          departmentId,
          subject: subject ?? department.name,
          type: ConversationType.DEPARTMENT_BROADCAST,
        },
        include: { participants: true },
      });
    }

    // Upsert sender + all volunteers as USER-type participants (matching identity resolution)
    const participantData = [
      { conversationId: conversation.id, participantType: sender.senderType, participantId: sender.senderId, lastReadAt: new Date() },
      ...department.eventVolunteers.map((ev) => ({
        conversationId: conversation!.id,
        participantType: 'USER' as MessageSenderType,
        participantId: ev.userId,
      })),
    ];
    await this.prisma.conversationParticipant.createMany({
      data: participantData,
      skipDuplicates: true,
    });

    // Create the broadcast message
    const message = await this.createBroadcastMessageInternal(sender, conversation.id, eventId, body, RecipientType.DEPARTMENT, departmentId);

    // Publish events to all volunteer participants
    this.publishBroadcastMessageEvents(message, department.eventVolunteers, eventId, conversation.id);

    return this.prisma.conversation.findUnique({
      where: { id: conversation.id },
      include: {
        participants: true,
        messages: { take: 1, orderBy: { createdAt: 'desc' }, include: { senderUser: true, senderVol: { include: { user: true } } } },
      },
    });
  }

  /**
   * Send broadcast to all volunteers in an event (admin only).
   * Uses a per-scope conversation thread so subsequent broadcasts land in the same thread.
   */
  async sendBroadcast(sender: SenderIdentity, input: SendBroadcastInput) {
    const result = sendBroadcastSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { eventId, subject, body } = result.data;

    const event = await this.prisma.event.findUnique({
      where: { id: eventId },
      include: {
        eventVolunteers: { select: { id: true, userId: true } },
      },
    });

    if (!event) throw new NotFoundError('Event');

    // Find or create broadcast conversation for this event
    let conversation = await this.prisma.conversation.findFirst({
      where: { type: ConversationType.EVENT_BROADCAST, eventId, departmentId: null },
      include: { participants: true },
    });

    if (!conversation) {
      conversation = await this.prisma.conversation.create({
        data: {
          eventId,
          subject: subject ?? 'Event Announcements',
          type: ConversationType.EVENT_BROADCAST,
        },
        include: { participants: true },
      });
    }

    // Upsert sender + all volunteers as USER-type participants (matching identity resolution)
    const participantData = [
      { conversationId: conversation.id, participantType: sender.senderType, participantId: sender.senderId, lastReadAt: new Date() },
      ...event.eventVolunteers.map((ev) => ({
        conversationId: conversation!.id,
        participantType: 'USER' as MessageSenderType,
        participantId: ev.userId,
      })),
    ];
    await this.prisma.conversationParticipant.createMany({
      data: participantData,
      skipDuplicates: true,
    });

    // Create the broadcast message
    const message = await this.createBroadcastMessageInternal(sender, conversation.id, eventId, body, RecipientType.EVENT, eventId);

    // Publish events to all volunteer participants
    this.publishBroadcastMessageEvents(message, event.eventVolunteers, eventId, conversation.id);

    return this.prisma.conversation.findUnique({
      where: { id: conversation.id },
      include: {
        participants: true,
        messages: { take: 1, orderBy: { createdAt: 'desc' }, include: { senderUser: true, senderVol: { include: { user: true } } } },
      },
    });
  }

  /**
   * Get inbox messages for a user.
   * Finds messages sent directly to the user (recipientType=USER) OR
   * sent to any of the user's EventVolunteer records.
   */
  async getInboxMessages(
    identity: SenderIdentity,
    filter?: MessageFilterInput,
    limit = 50,
    offset = 0
  ) {
    // Find all EventVolunteer IDs for this user
    const evIds = await this.prisma.eventVolunteer.findMany({
      where: { userId: identity.senderId },
      select: { id: true },
    });
    const eventVolunteerIds = evIds.map((e) => e.id);

    const recipientConditions: Prisma.MessageWhereInput[] = [
      { recipientType: RecipientType.USER, recipientId: identity.senderId },
    ];
    if (eventVolunteerIds.length > 0) {
      recipientConditions.push({ eventVolunteerId: { in: eventVolunteerIds } });
    }

    const where: Prisma.MessageWhereInput = {
      deletedByRecipient: false,
      OR: recipientConditions,
    };

    if (filter?.isRead !== undefined) where.isRead = filter.isRead;
    if (filter?.senderId) where.senderUserId = filter.senderId;
    if (filter?.search) {
      where.AND = [
        {
          OR: [
            { subject: { contains: filter.search, mode: 'insensitive' } },
            { body: { contains: filter.search, mode: 'insensitive' } },
          ],
        },
      ];
    }

    return this.prisma.message.findMany({
      where,
      include: {
        senderUser: true,
        senderVol: { include: { user: true } },
        event: true,
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset,
    });
  }

  /**
   * Get unread message count for a user
   */
  async getUnreadCount(identity: SenderIdentity): Promise<number> {
    const evIds = await this.prisma.eventVolunteer.findMany({
      where: { userId: identity.senderId },
      select: { id: true },
    });
    const eventVolunteerIds = evIds.map((e) => e.id);

    const recipientConditions: Prisma.MessageWhereInput[] = [
      { recipientType: RecipientType.USER, recipientId: identity.senderId },
    ];
    if (eventVolunteerIds.length > 0) {
      recipientConditions.push({ eventVolunteerId: { in: eventVolunteerIds } });
    }

    return this.prisma.message.count({
      where: {
        isRead: false,
        deletedByRecipient: false,
        OR: recipientConditions,
      },
    });
  }

  /**
   * Mark message as read (any user)
   */
  async markAsRead(messageId: string, identity: SenderIdentity): Promise<Message> {
    const message = await this.prisma.message.findUnique({
      where: { id: messageId },
    });

    if (!message) throw new NotFoundError('Message');

    // Check ownership: direct USER recipient OR message to user's EventVolunteer
    let isRecipient =
      message.recipientType === RecipientType.USER && message.recipientId === identity.senderId;

    if (!isRecipient && message.eventVolunteerId) {
      const ev = await this.prisma.eventVolunteer.findUnique({
        where: { id: message.eventVolunteerId },
        select: { userId: true },
      });
      isRecipient = ev?.userId === identity.senderId;
    }

    if (!isRecipient) {
      throw new AuthorizationError('This message does not belong to you');
    }

    if (message.isRead) {
      return this.prisma.message.findUnique({
        where: { id: messageId },
        include: { senderUser: true, event: true },
      }) as Promise<Message>;
    }

    return this.prisma.message.update({
      where: { id: messageId },
      data: { isRead: true, readAt: new Date() },
      include: { senderUser: true, event: true },
    });
  }

  /**
   * Mark all messages as read for a user within an event
   */
  async markAllAsRead(identity: SenderIdentity, eventId?: string): Promise<number> {
    const evIds = await this.prisma.eventVolunteer.findMany({
      where: { userId: identity.senderId },
      select: { id: true },
    });
    const eventVolunteerIds = evIds.map((e) => e.id);

    const recipientConditions: Prisma.MessageWhereInput[] = [
      { recipientType: RecipientType.USER, recipientId: identity.senderId },
    ];
    if (eventVolunteerIds.length > 0) {
      recipientConditions.push({ eventVolunteerId: { in: eventVolunteerIds } });
    }

    const where: Prisma.MessageWhereInput = {
      isRead: false,
      deletedByRecipient: false,
      OR: recipientConditions,
    };

    if (eventId) where.eventId = eventId;

    const result = await this.prisma.message.updateMany({
      where,
      data: { isRead: true, readAt: new Date() },
    });

    return result.count;
  }

  /**
   * Get message by ID
   */
  async getMessage(messageId: string) {
    return this.prisma.message.findUnique({
      where: { id: messageId },
      include: {
        senderUser: true,
        senderVol: { include: { user: true } },
        event: true,
        conversation: true,
      },
    });
  }

  /**
   * Get sent messages for an admin
   */
  async getSentMessages(senderId: string, limit = 50, offset = 0) {
    return this.prisma.message.findMany({
      where: {
        senderUserId: senderId,
        deletedBySender: false,
      },
      include: { event: true },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset,
    });
  }

  /**
   * Soft delete a message for sender or recipient
   */
  async softDeleteMessage(messageId: string, identity: SenderIdentity): Promise<boolean> {
    const message = await this.prisma.message.findUnique({
      where: { id: messageId },
    });

    if (!message) throw new NotFoundError('Message');

    // Determine if the user is the sender or recipient
    const isSender = message.senderUserId === identity.senderId;

    let isRecipient =
      message.recipientType === RecipientType.USER && message.recipientId === identity.senderId;

    if (!isRecipient && message.eventVolunteerId) {
      const ev = await this.prisma.eventVolunteer.findUnique({
        where: { id: message.eventVolunteerId },
        select: { userId: true },
      });
      isRecipient = ev?.userId === identity.senderId;
    }

    if (!isSender && !isRecipient) {
      throw new AuthorizationError('You cannot delete this message');
    }

    const data: Prisma.MessageUpdateInput = {};
    if (isSender) data.deletedBySender = true;
    if (isRecipient) data.deletedByRecipient = true;

    await this.prisma.message.update({
      where: { id: messageId },
      data,
    });

    return true;
  }

  // ─── New Conversation Methods ────────────────────────────────────────

  /**
   * Start a new conversation thread (or return existing one between same participants)
   */
  async startConversation(sender: SenderIdentity, input: StartConversationInput) {
    const result = startConversationSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { eventId, recipientType, recipientId, subject, body } = result.data;

    // Prevent self-messaging
    if (sender.senderType === recipientType && sender.senderId === recipientId) {
      throw new ValidationError('You cannot start a conversation with yourself');
    }

    // Check if a DIRECT conversation already exists between these two participants
    const existing = await this.prisma.conversation.findFirst({
      where: {
        eventId,
        type: ConversationType.DIRECT,
        AND: [
          {
            participants: {
              some: {
                participantType: sender.senderType,
                participantId: sender.senderId,
              },
            },
          },
          {
            participants: {
              some: {
                participantType: recipientType as MessageSenderType,
                participantId: recipientId,
              },
            },
          },
        ],
      },
      include: { participants: true, messages: { take: 1, orderBy: { createdAt: 'desc' } } },
    });

    if (existing) {
      // Un-delete for sender if they previously deleted it
      await this.prisma.conversationParticipant.updateMany({
        where: {
          conversationId: existing.id,
          participantType: sender.senderType,
          participantId: sender.senderId,
          deletedAt: { not: null },
        },
        data: { deletedAt: null },
      });

      // Send the message in the existing conversation
      await this.createConversationMessageInternal(sender, existing.id, eventId, body);

      return this.prisma.conversation.findUnique({
        where: { id: existing.id },
        include: { participants: true, messages: { take: 1, orderBy: { createdAt: 'desc' } } },
      });
    }

    // Create new conversation with participants and first message
    const conversation = await this.prisma.conversation.create({
      data: {
        eventId,
        subject,
        participants: {
          create: [
            {
              participantType: sender.senderType,
              participantId: sender.senderId,
              lastReadAt: new Date(),
            },
            {
              participantType: recipientType as MessageSenderType,
              participantId: recipientId,
            },
          ],
        },
      },
      include: { participants: true },
    });

    // Create the first message
    await this.createConversationMessageInternal(sender, conversation.id, eventId, body);

    return this.prisma.conversation.findUnique({
      where: { id: conversation.id },
      include: { participants: true, messages: { take: 1, orderBy: { createdAt: 'desc' } } },
    });
  }

  /**
   * Send a reply in an existing conversation
   */
  async sendConversationMessage(
    sender: SenderIdentity,
    input: SendConversationMessageInput
  ): Promise<Message> {
    const result = sendConversationMessageSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { conversationId, body } = result.data;

    // Verify conversation exists and sender is a participant
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: { participants: true },
    });

    if (!conversation) throw new NotFoundError('Conversation');

    const participant = conversation.participants.find(
      (p) => p.participantType === sender.senderType && p.participantId === sender.senderId
    );

    if (!participant) {
      throw new AuthorizationError('You are not a participant in this conversation');
    }

    return this.createConversationMessageInternal(
      sender,
      conversationId,
      conversation.eventId,
      body
    );
  }

  /**
   * Get conversations for a user
   */
  async getConversations(identity: SenderIdentity, eventId: string, limit = 50, offset = 0) {
    return this.prisma.conversation.findMany({
      where: {
        eventId,
        participants: {
          some: {
            participantType: identity.senderType,
            participantId: identity.senderId,
            deletedAt: null,
          },
        },
      },
      include: {
        participants: true,
        messages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
          include: {
            senderUser: true,
            senderVol: { include: { user: true } },
          },
        },
      },
      orderBy: { updatedAt: 'desc' },
      take: limit,
      skip: offset,
    });
  }

  /**
   * Get messages in a conversation thread
   */
  async getConversationMessages(
    conversationId: string,
    identity: SenderIdentity,
    limit = 50,
    offset = 0
  ) {
    // Verify participant
    const participant = await this.prisma.conversationParticipant.findFirst({
      where: {
        conversationId,
        participantType: identity.senderType,
        participantId: identity.senderId,
      },
    });

    if (!participant) {
      throw new AuthorizationError('You are not a participant in this conversation');
    }

    return this.prisma.message.findMany({
      where: { conversationId },
      include: {
        senderUser: true,
        senderVol: { include: { user: true } },
      },
      orderBy: { createdAt: 'asc' },
      take: limit,
      skip: offset,
    });
  }

  /**
   * Mark a conversation as read for a participant
   */
  async markConversationRead(conversationId: string, identity: SenderIdentity) {
    const participant = await this.prisma.conversationParticipant.findFirst({
      where: {
        conversationId,
        participantType: identity.senderType,
        participantId: identity.senderId,
      },
    });

    if (!participant) {
      throw new AuthorizationError('You are not a participant in this conversation');
    }

    await this.prisma.conversationParticipant.update({
      where: { id: participant.id },
      data: { lastReadAt: new Date() },
    });

    // Mark individual messages in this conversation as read for the user
    const recipientConditions: Prisma.MessageWhereInput[] = [
      { recipientType: RecipientType.USER, recipientId: identity.senderId },
    ];
    const evIds = await this.prisma.eventVolunteer.findMany({
      where: { userId: identity.senderId },
      select: { id: true },
    });
    if (evIds.length > 0) {
      recipientConditions.push({ eventVolunteerId: { in: evIds.map((e) => e.id) } });
    }

    await this.prisma.message.updateMany({
      where: {
        conversationId,
        isRead: false,
        OR: recipientConditions,
      },
      data: { isRead: true, readAt: new Date() },
    });

    // Delete message notifications for this conversation
    await this.prisma.notification.deleteMany({
      where: {
        userId: identity.senderId,
        data: { path: ['conversationId'], equals: conversationId },
      },
    });

    // Publish updated unread count so badge updates in real-time
    const freshCount = await this.getUnreadCount(identity);
    pubsub.publish(UNREAD_COUNT_UPDATED, {
      unreadCountUpdated: { userId: identity.senderId, count: freshCount },
    });

    return this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: { participants: true },
    });
  }

  /**
   * Soft delete a conversation for a participant
   */
  async deleteConversation(conversationId: string, identity: SenderIdentity): Promise<boolean> {
    const participant = await this.prisma.conversationParticipant.findFirst({
      where: {
        conversationId,
        participantType: identity.senderType,
        participantId: identity.senderId,
      },
    });

    if (!participant) {
      throw new AuthorizationError('You are not a participant in this conversation');
    }

    await this.prisma.conversationParticipant.update({
      where: { id: participant.id },
      data: { deletedAt: new Date() },
    });

    return true;
  }

  /**
   * Send a message to multiple volunteers at once
   */
  async sendMultiMessage(sender: SenderIdentity, input: SendMultiMessageInput): Promise<Message[]> {
    const result = sendMultiMessageSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { volunteerIds, subject, body, eventId } = result.data;

    // Verify all eventVolunteers exist
    const eventVolunteers2 = await this.prisma.eventVolunteer.findMany({
      where: { id: { in: volunteerIds }, eventId },
      select: { id: true, userId: true },
    });

    if (eventVolunteers2.length === 0) throw new ValidationError('No valid volunteers found');

    const messages = await this.prisma.$transaction(
      eventVolunteers2.map((ev) =>
        this.prisma.message.create({
          data: {
            subject,
            body,
            recipientType: RecipientType.VOLUNTEER,
            recipientId: ev.id,
            eventId,
            senderType: sender.senderType,
            senderUserId: sender.senderType === 'USER' ? sender.senderId : null,
            senderVolId: sender.senderType === 'VOLUNTEER' ? sender.senderId : null,
            eventVolunteerId: ev.id,
          },
          include: { senderUser: true, event: true },
        })
      )
    );

    // Publish subscription events per recipient
    for (const ev of eventVolunteers2) {
      const msg = messages.find((m) => m.eventVolunteerId === ev.id);
      if (msg) this.publishMessageEvents(msg, ev.userId, eventId);
    }

    return messages;
  }

  /**
   * Search messages by subject + body (ILIKE)
   */
  async searchMessages(
    identity: SenderIdentity,
    input: SearchMessagesInput,
    limit = 50,
    offset = 0
  ) {
    const result = searchMessagesSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { eventId, query } = result.data;

    // Build recipient filter based on user type
    const recipientFilter: Prisma.MessageWhereInput =
      identity.senderType === 'VOLUNTEER'
        ? {
            OR: [{ eventVolunteerId: identity.senderId }, { senderVolId: identity.senderId }],
          }
        : {
            OR: [
              { senderUserId: identity.senderId },
              { recipientType: RecipientType.USER, recipientId: identity.senderId },
            ],
          };

    return this.prisma.message.findMany({
      where: {
        eventId,
        deletedByRecipient: false,
        deletedBySender: false,
        AND: [
          recipientFilter,
          {
            OR: [
              { subject: { contains: query, mode: 'insensitive' } },
              { body: { contains: query, mode: 'insensitive' } },
            ],
          },
        ],
      },
      include: {
        senderUser: true,
        senderVol: { include: { user: true } },
        event: true,
        conversation: true,
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset,
    });
  }

  // ─── Helper Methods ──────────────────────────────────────────────────

  /**
   * Internal: Create a message inside a conversation
   */
  private async createConversationMessageInternal(
    sender: SenderIdentity,
    conversationId: string,
    eventId: string,
    body: string
  ): Promise<Message> {
    // Get the other participant to set as recipient
    const otherParticipant = await this.prisma.conversationParticipant.findFirst({
      where: {
        conversationId,
        NOT: {
          participantType: sender.senderType,
          participantId: sender.senderId,
        },
      },
    });

    const recipientType =
      otherParticipant?.participantType === 'USER' ? RecipientType.USER : RecipientType.VOLUNTEER;

    const message = await this.prisma.message.create({
      data: {
        body,
        recipientType,
        recipientId: otherParticipant?.participantId ?? '',
        eventId,
        conversationId,
        senderType: sender.senderType,
        senderUserId: sender.senderType === 'USER' ? sender.senderId : null,
        senderVolId: sender.senderType === 'VOLUNTEER' ? sender.senderId : null,
        // Set volunteer FK if recipient is a volunteer (for legacy compat)
        eventVolunteerId:
          recipientType === RecipientType.VOLUNTEER
            ? (otherParticipant?.participantId ?? null)
            : null,
      },
      include: {
        senderUser: true,
        senderVol: { include: { user: true } },
      },
    });

    // Update conversation's updatedAt
    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: { updatedAt: new Date() },
    });

    // Update sender's lastReadAt
    await this.prisma.conversationParticipant.updateMany({
      where: {
        conversationId,
        participantType: sender.senderType,
        participantId: sender.senderId,
      },
      data: { lastReadAt: new Date() },
    });

    // Publish subscription events for conversation message
    if (otherParticipant) {
      let recipientUserId = otherParticipant.participantId;
      if (otherParticipant.participantType === 'VOLUNTEER') {
        const resolved = await this.resolveEventVolunteerUserId(otherParticipant.participantId);
        if (resolved) recipientUserId = resolved;
      }
      this.publishMessageEvents(message, recipientUserId, eventId, conversationId);
    }

    return message;
  }

  /**
   * Internal: Create a single message inside a broadcast conversation.
   * Unlike createConversationMessageInternal, this has no single recipient —
   * all participants receive via subscription events.
   */
  private async createBroadcastMessageInternal(
    sender: SenderIdentity,
    conversationId: string,
    eventId: string,
    body: string,
    recipientType: RecipientType,
    recipientId: string
  ): Promise<Message> {
    const message = await this.prisma.message.create({
      data: {
        body,
        recipientType,
        recipientId,
        eventId,
        conversationId,
        senderType: sender.senderType,
        senderUserId: sender.senderType === 'USER' ? sender.senderId : null,
        senderVolId: sender.senderType === 'VOLUNTEER' ? sender.senderId : null,
      },
      include: {
        senderUser: true,
        senderVol: { include: { user: true } },
      },
    });

    // Update conversation's updatedAt
    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: { updatedAt: new Date() },
    });

    // Update sender's lastReadAt
    await this.prisma.conversationParticipant.updateMany({
      where: {
        conversationId,
        participantType: sender.senderType,
        participantId: sender.senderId,
      },
      data: { lastReadAt: new Date() },
    });

    return message;
  }

  /**
   * Publish subscription + push notification events for a broadcast message.
   * Loops over all volunteer participants (excluding sender).
   * Fire-and-forget — never throws.
   */
  private async publishBroadcastMessageEvents(
    message: Message,
    volunteers: Array<{ id: string; userId: string }>,
    eventId: string,
    conversationId: string
  ): Promise<void> {
    try {
      for (const volunteer of volunteers) {
        this.publishMessageEvents(message, volunteer.userId, eventId, conversationId);
      }
    } catch {
      // Subscription/push failures should never break message sending
    }
  }

  /**
   * Publish subscription events for a newly created message.
   * Fire-and-forget — never throws.
   */
  private async publishMessageEvents(
    message: Message,
    recipientUserId: string,
    eventId: string,
    conversationId?: string | null
  ): Promise<void> {
    try {
      const payload = { ...message, recipientUserId, eventId };

      pubsub.publish(MESSAGE_RECEIVED, { messageReceived: payload });

      if (conversationId) {
        pubsub.publish(CONVERSATION_MESSAGE_RECEIVED, {
          conversationMessageReceived: { ...payload, conversationId },
        });
      }

      // Compute fresh unread count for recipient
      const evIds = await this.prisma.eventVolunteer.findMany({
        where: { userId: recipientUserId },
        select: { id: true },
      });
      const eventVolunteerIds = evIds.map((e) => e.id);

      const recipientConditions: Prisma.MessageWhereInput[] = [
        { recipientType: RecipientType.USER, recipientId: recipientUserId },
      ];
      if (eventVolunteerIds.length > 0) {
        recipientConditions.push({ eventVolunteerId: { in: eventVolunteerIds } });
      }

      const count = await this.prisma.message.count({
        where: {
          isRead: false,
          deletedByRecipient: false,
          OR: recipientConditions,
        },
      });

      pubsub.publish(UNREAD_COUNT_UPDATED, {
        unreadCountUpdated: { userId: recipientUserId, count },
      });

      // Send push notification
      const notifType = conversationId ? 'CONVERSATION_MESSAGE' : this.getNotificationType(message);
      const preview = message.body.length > 100 ? message.body.slice(0, 100) + '…' : message.body;

      // Resolve sender name for push title
      let senderName = 'New Message';
      if (message.senderUserId) {
        const sender = await this.prisma.user.findUnique({
          where: { id: message.senderUserId },
          select: { firstName: true, lastName: true },
        });
        if (sender) senderName = `${sender.firstName} ${sender.lastName}`;
      } else if (message.senderVolId) {
        const sender = await this.prisma.eventVolunteer.findUnique({
          where: { id: message.senderVolId },
          include: { user: { select: { firstName: true, lastName: true } } },
        });
        if (sender) senderName = `${sender.user.firstName} ${sender.user.lastName}`;
      }

      const pushTitle = notifType === 'DEPARTMENT_MESSAGE'
        ? 'Department Message'
        : notifType === 'BROADCAST'
          ? 'Event Announcement'
          : senderName;

      this.notificationService.sendToUser(recipientUserId, eventId, {
        title: pushTitle,
        body: preview,
        data: {
          type: notifType,
          messageId: message.id,
          eventId,
          ...(conversationId && { conversationId }),
        },
      });
    } catch {
      // Subscription/push failures should never break message sending
    }
  }

  /**
   * Map message recipientType to push notification type string.
   */
  private getNotificationType(message: Message): string {
    switch (message.recipientType) {
      case 'DEPARTMENT': return 'DEPARTMENT_MESSAGE';
      case 'EVENT': return 'BROADCAST';
      default: return 'NEW_MESSAGE';
    }
  }

  /**
   * Resolve the userId for an EventVolunteer.
   */
  private async resolveEventVolunteerUserId(eventVolunteerId: string): Promise<string | null> {
    const ev = await this.prisma.eventVolunteer.findUnique({
      where: { id: eventVolunteerId },
      select: { userId: true },
    });
    return ev?.userId ?? null;
  }

  /**
   * Get volunteer's eventId for access control
   */
  async getVolunteerEventId(eventVolunteerId: string): Promise<string> {
    const ev = await this.prisma.eventVolunteer.findUnique({
      where: { id: eventVolunteerId },
      select: { eventId: true },
    });

    if (!ev) throw new NotFoundError('EventVolunteer');
    return ev.eventId;
  }

  /**
   * Get department's eventId for access control
   */
  async getDepartmentEventId(departmentId: string): Promise<string> {
    const department = await this.prisma.department.findUnique({
      where: { id: departmentId },
      select: { eventId: true },
    });

    if (!department) throw new NotFoundError('Department');
    return department.eventId;
  }
}
