/**
 * Message Service
 *
 * Business logic for bi-directional messaging between overseers, volunteers,
 * and conversation threads.
 *
 * Existing methods (updated for dual-auth):
 *   - sendMessage: Send to individual (admin or volunteer sender)
 *   - sendDepartmentMessage: Broadcast to department (admin only)
 *   - sendBroadcast: Broadcast to event (admin only)
 *   - getInboxMessages: Get messages for any user (was getVolunteerMessages)
 *   - getUnreadCount: Get unread count for any user
 *   - markAsRead: Mark single message as read (any user)
 *   - markAllAsRead: Mark all as read (any user)
 *   - getMessage: Get message by ID
 *   - getSentMessages: Get sent messages (admin)
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
import { Prisma, PrismaClient, Message, MessageSenderType, RecipientType } from '@prisma/client';
import { NotFoundError, ValidationError, AuthorizationError } from '../utils/errors';
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
  constructor(private prisma: PrismaClient) {}

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
    if (recipientType && recipientId && sender.senderType === recipientType && sender.senderId === recipientId) {
      throw new ValidationError('You cannot send a message to yourself');
    }

    if (recipientType === 'ADMIN' && recipientId) {
      // Sending to an admin — create a message with ADMIN recipientType
      const admin = await this.prisma.admin.findUnique({
        where: { id: recipientId },
        select: { id: true },
      });
      if (!admin) throw new NotFoundError('Admin');

      return this.prisma.message.create({
        data: {
          subject,
          body,
          recipientType: RecipientType.ADMIN,
          recipientId: recipientId,
          eventId,
          senderType: sender.senderType,
          senderAdminId: sender.senderType === 'ADMIN' ? sender.senderId : null,
          senderVolId: sender.senderType === 'VOLUNTEER' ? sender.senderId : null,
          // Legacy fields for backward compat
          senderId: sender.senderType === 'ADMIN' ? sender.senderId : null,
        },
        include: { senderAdmin: true, volunteer: true, event: true },
      });
    }

    // Sending to a volunteer — use volunteerId (legacy) or recipientId (new)
    const volId = targetVolunteerId || recipientId;
    if (!volId) throw new ValidationError('Volunteer ID or recipient ID is required');

    // Verify volunteer exists
    const volunteer = await this.prisma.volunteer.findUnique({
      where: { id: volId },
      select: { id: true, volunteerId: true, eventId: true },
    });

    if (!volunteer) throw new NotFoundError('Volunteer');

    // Resolve matching EventVolunteer
    const eventVolunteer = await this.prisma.eventVolunteer.findFirst({
      where: { volunteerId: volunteer.volunteerId, eventId: volunteer.eventId },
      select: { id: true },
    });

    return this.prisma.message.create({
      data: {
        subject,
        body,
        recipientType: RecipientType.VOLUNTEER,
        recipientId: volId,
        eventId: volunteer.eventId,
        senderType: sender.senderType,
        senderAdminId: sender.senderType === 'ADMIN' ? sender.senderId : null,
        senderVolId: sender.senderType === 'VOLUNTEER' ? sender.senderId : null,
        // Legacy fields
        senderId: sender.senderType === 'ADMIN' ? sender.senderId : null,
        volunteerId: volId,
        eventVolunteerId: eventVolunteer?.id ?? null,
      },
      include: { senderAdmin: true, volunteer: true, event: true },
    });
  }

  /**
   * Send message to all volunteers in a department (admin only)
   */
  async sendDepartmentMessage(
    sender: SenderIdentity,
    input: SendDepartmentMessageInput
  ): Promise<Message[]> {
    const result = sendDepartmentMessageSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { departmentId, subject, body } = result.data;

    const department = await this.prisma.department.findUnique({
      where: { id: departmentId },
      include: {
        volunteers: { select: { id: true, volunteerId: true } },
        event: { select: { id: true } },
      },
    });

    if (!department) throw new NotFoundError('Department');
    if (department.volunteers.length === 0) return [];

    const eventVolunteers = await this.prisma.eventVolunteer.findMany({
      where: { departmentId },
      select: { id: true, volunteerId: true },
    });
    const evMap = new Map(eventVolunteers.map((ev) => [ev.volunteerId, ev.id]));

    const messages = await this.prisma.$transaction(
      department.volunteers.map((volunteer) =>
        this.prisma.message.create({
          data: {
            subject,
            body,
            recipientType: RecipientType.DEPARTMENT,
            recipientId: departmentId,
            eventId: department.event.id,
            senderType: sender.senderType,
            senderAdminId: sender.senderType === 'ADMIN' ? sender.senderId : null,
            senderVolId: sender.senderType === 'VOLUNTEER' ? sender.senderId : null,
            senderId: sender.senderType === 'ADMIN' ? sender.senderId : null,
            volunteerId: volunteer.id,
            eventVolunteerId: evMap.get(volunteer.volunteerId) ?? null,
          },
          include: { senderAdmin: true, volunteer: true, event: true },
        })
      )
    );

    return messages;
  }

  /**
   * Send broadcast to all volunteers in an event (admin only)
   */
  async sendBroadcast(sender: SenderIdentity, input: SendBroadcastInput): Promise<Message[]> {
    const result = sendBroadcastSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { eventId, subject, body } = result.data;

    const event = await this.prisma.event.findUnique({
      where: { id: eventId },
      include: {
        volunteers: { select: { id: true, volunteerId: true } },
      },
    });

    if (!event) throw new NotFoundError('Event');
    if (event.volunteers.length === 0) return [];

    const eventVolunteers = await this.prisma.eventVolunteer.findMany({
      where: { eventId },
      select: { id: true, volunteerId: true },
    });
    const evMap = new Map(eventVolunteers.map((ev) => [ev.volunteerId, ev.id]));

    const messages = await this.prisma.$transaction(
      event.volunteers.map((volunteer) =>
        this.prisma.message.create({
          data: {
            subject,
            body,
            recipientType: RecipientType.EVENT,
            recipientId: eventId,
            eventId,
            senderType: sender.senderType,
            senderAdminId: sender.senderType === 'ADMIN' ? sender.senderId : null,
            senderVolId: sender.senderType === 'VOLUNTEER' ? sender.senderId : null,
            senderId: sender.senderType === 'ADMIN' ? sender.senderId : null,
            volunteerId: volunteer.id,
            eventVolunteerId: evMap.get(volunteer.volunteerId) ?? null,
          },
          include: { senderAdmin: true, volunteer: true, event: true },
        })
      )
    );

    return messages;
  }

  /**
   * Get inbox messages for any user (volunteers or admins).
   * For volunteers: messages where they are the recipient.
   * For admins: messages where recipientType=ADMIN and recipientId matches.
   */
  async getInboxMessages(
    identity: SenderIdentity,
    filter?: MessageFilterInput,
    limit = 50,
    offset = 0
  ) {
    const where: Prisma.MessageWhereInput = {
      deletedByRecipient: false,
    };

    if (identity.senderType === 'VOLUNTEER') {
      where.OR = [
        { volunteerId: identity.senderId },
        { eventVolunteerId: identity.senderId },
      ];
    } else {
      // Admin inbox: messages sent TO this admin
      where.recipientType = RecipientType.ADMIN;
      where.recipientId = identity.senderId;
    }

    if (filter?.isRead !== undefined) where.isRead = filter.isRead;
    if (filter?.senderId) where.senderId = filter.senderId;
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
        senderAdmin: true,
        senderVol: { include: { volunteerProfile: true } },
        sender: true,
        event: true,
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset,
    });
  }

  /**
   * Get unread message count for any user
   */
  async getUnreadCount(identity: SenderIdentity): Promise<number> {
    const where: Prisma.MessageWhereInput = {
      isRead: false,
      deletedByRecipient: false,
    };

    if (identity.senderType === 'VOLUNTEER') {
      where.OR = [
        { volunteerId: identity.senderId },
        { eventVolunteerId: identity.senderId },
      ];
    } else {
      where.recipientType = RecipientType.ADMIN;
      where.recipientId = identity.senderId;
    }

    return this.prisma.message.count({ where });
  }

  /**
   * Mark message as read (any user)
   */
  async markAsRead(messageId: string, identity: SenderIdentity): Promise<Message> {
    const message = await this.prisma.message.findUnique({
      where: { id: messageId },
    });

    if (!message) throw new NotFoundError('Message');

    // Check ownership: volunteer recipient OR admin recipient
    const isRecipient =
      (identity.senderType === 'VOLUNTEER' &&
        (message.volunteerId === identity.senderId ||
          message.eventVolunteerId === identity.senderId)) ||
      (identity.senderType === 'ADMIN' &&
        message.recipientType === RecipientType.ADMIN &&
        message.recipientId === identity.senderId);

    if (!isRecipient) {
      throw new AuthorizationError('This message does not belong to you');
    }

    if (message.isRead) {
      return this.prisma.message.findUnique({
        where: { id: messageId },
        include: { senderAdmin: true, sender: true, event: true },
      }) as Promise<Message>;
    }

    return this.prisma.message.update({
      where: { id: messageId },
      data: { isRead: true, readAt: new Date() },
      include: { senderAdmin: true, sender: true, event: true },
    });
  }

  /**
   * Mark all messages as read for a user within an event
   */
  async markAllAsRead(identity: SenderIdentity, eventId?: string): Promise<number> {
    const where: Prisma.MessageWhereInput = {
      isRead: false,
      deletedByRecipient: false,
    };

    if (eventId) where.eventId = eventId;

    if (identity.senderType === 'VOLUNTEER') {
      where.OR = [
        { volunteerId: identity.senderId },
        { eventVolunteerId: identity.senderId },
      ];
    } else {
      where.recipientType = RecipientType.ADMIN;
      where.recipientId = identity.senderId;
    }

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
        senderAdmin: true,
        senderVol: { include: { volunteerProfile: true } },
        sender: true,
        volunteer: true,
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
        OR: [{ senderId }, { senderAdminId: senderId }],
        deletedBySender: false,
      },
      include: { volunteer: true, event: true },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset,
    });
  }

  /**
   * Soft delete a message for sender or recipient
   */
  async softDeleteMessage(
    messageId: string,
    identity: SenderIdentity
  ): Promise<boolean> {
    const message = await this.prisma.message.findUnique({
      where: { id: messageId },
    });

    if (!message) throw new NotFoundError('Message');

    // Determine if the user is the sender or recipient
    const isSender =
      (identity.senderType === 'ADMIN' &&
        (message.senderAdminId === identity.senderId || message.senderId === identity.senderId)) ||
      (identity.senderType === 'VOLUNTEER' && message.senderVolId === identity.senderId);

    const isRecipient =
      (identity.senderType === 'VOLUNTEER' &&
        (message.volunteerId === identity.senderId ||
          message.eventVolunteerId === identity.senderId)) ||
      (identity.senderType === 'ADMIN' &&
        message.recipientType === RecipientType.ADMIN &&
        message.recipientId === identity.senderId);

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
  async startConversation(
    sender: SenderIdentity,
    input: StartConversationInput
  ) {
    const result = startConversationSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { eventId, recipientType, recipientId, subject, body } = result.data;

    // Prevent self-messaging
    if (sender.senderType === recipientType && sender.senderId === recipientId) {
      throw new ValidationError('You cannot start a conversation with yourself');
    }

    // Check if a conversation already exists between these two participants
    const existing = await this.prisma.conversation.findFirst({
      where: {
        eventId,
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
  async getConversations(
    identity: SenderIdentity,
    eventId: string,
    limit = 50,
    offset = 0
  ) {
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
            senderAdmin: true,
            senderVol: { include: { volunteerProfile: true } },
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
        senderAdmin: true,
        senderVol: { include: { volunteerProfile: true } },
      },
      orderBy: { createdAt: 'asc' },
      take: limit,
      skip: offset,
    });
  }

  /**
   * Mark a conversation as read for a participant
   */
  async markConversationRead(
    conversationId: string,
    identity: SenderIdentity
  ) {
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

    return this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: { participants: true },
    });
  }

  /**
   * Soft delete a conversation for a participant
   */
  async deleteConversation(
    conversationId: string,
    identity: SenderIdentity
  ): Promise<boolean> {
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
  async sendMultiMessage(
    sender: SenderIdentity,
    input: SendMultiMessageInput
  ): Promise<Message[]> {
    const result = sendMultiMessageSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { volunteerIds, subject, body, eventId } = result.data;

    // Verify all volunteers exist
    const volunteers = await this.prisma.volunteer.findMany({
      where: { id: { in: volunteerIds } },
      select: { id: true, volunteerId: true, eventId: true },
    });

    if (volunteers.length === 0) throw new ValidationError('No valid volunteers found');

    // Build EventVolunteer lookup
    const evs = await this.prisma.eventVolunteer.findMany({
      where: { eventId, volunteerId: { in: volunteers.map((v) => v.volunteerId) } },
      select: { id: true, volunteerId: true },
    });
    const evMap = new Map(evs.map((ev) => [ev.volunteerId, ev.id]));

    const messages = await this.prisma.$transaction(
      volunteers.map((volunteer) =>
        this.prisma.message.create({
          data: {
            subject,
            body,
            recipientType: RecipientType.VOLUNTEER,
            recipientId: volunteer.id,
            eventId,
            senderType: sender.senderType,
            senderAdminId: sender.senderType === 'ADMIN' ? sender.senderId : null,
            senderVolId: sender.senderType === 'VOLUNTEER' ? sender.senderId : null,
            senderId: sender.senderType === 'ADMIN' ? sender.senderId : null,
            volunteerId: volunteer.id,
            eventVolunteerId: evMap.get(volunteer.volunteerId) ?? null,
          },
          include: { senderAdmin: true, volunteer: true, event: true },
        })
      )
    );

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
            OR: [
              { volunteerId: identity.senderId },
              { eventVolunteerId: identity.senderId },
              { senderVolId: identity.senderId },
            ],
          }
        : {
            OR: [
              { senderAdminId: identity.senderId },
              { senderId: identity.senderId },
              { recipientType: RecipientType.ADMIN, recipientId: identity.senderId },
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
        senderAdmin: true,
        senderVol: { include: { volunteerProfile: true } },
        sender: true,
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
      otherParticipant?.participantType === 'ADMIN'
        ? RecipientType.ADMIN
        : RecipientType.VOLUNTEER;

    const message = await this.prisma.message.create({
      data: {
        body,
        recipientType,
        recipientId: otherParticipant?.participantId ?? '',
        eventId,
        conversationId,
        senderType: sender.senderType,
        senderAdminId: sender.senderType === 'ADMIN' ? sender.senderId : null,
        senderVolId: sender.senderType === 'VOLUNTEER' ? sender.senderId : null,
        senderId: sender.senderType === 'ADMIN' ? sender.senderId : null,
        // Set volunteer FK if recipient is a volunteer (for legacy compat)
        eventVolunteerId:
          recipientType === RecipientType.VOLUNTEER
            ? otherParticipant?.participantId ?? null
            : null,
      },
      include: {
        senderAdmin: true,
        senderVol: { include: { volunteerProfile: true } },
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
   * Get volunteer's eventId for access control
   */
  async getVolunteerEventId(volunteerId: string): Promise<string> {
    const volunteer = await this.prisma.volunteer.findUnique({
      where: { id: volunteerId },
      select: { eventId: true },
    });

    if (!volunteer) throw new NotFoundError('Volunteer');
    return volunteer.eventId;
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
