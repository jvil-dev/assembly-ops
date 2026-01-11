/**
 * Message Service
 *
 * Business logic for messaging between overseers and volunteers.
 *
 * Methods:
 *   - sendMessage(senderId, input): Send message to individual volunteer
 *   - sendDepartmentMessage(senderId, input): Broadcast to all department volunteers
 *   - sendBroadcast(senderId, input): Broadcast to all event volunteers
 *   - getVolunteerMessages(volunteerId, filter, limit, offset): Get messages for volunteer
 *   - getUnreadCount(volunteerId): Get unread message count
 *   - markAsRead(messageId, volunteerId): Mark single message as read
 *   - markAllAsRead(volunteerId): Mark all messages as read
 *   - getMessage(messageId): Get message by ID
 *   - getSentMessages(senderId, limit, offset): Get messages sent by admin
 *   - deleteMessage(messageId): Delete a message
 */
import { Prisma, PrismaClient, Message, RecipientType } from '@prisma/client';
import { NotFoundError, ValidationError, AuthorizationError } from '../utils/errors';
import {
  sendMessageSchema,
  sendDepartmentMessageSchema,
  sendBroadcastSchema,
  SendMessageInput,
  SendDepartmentMessageInput,
  SendBroadcastInput,
  MessageFilterInput,
} from '../graphql/validators/message.js';

export class MessageService {
  constructor(private prisma: PrismaClient) {}

  /**
   * Send message to individual volunteer
   */
  async sendMessage(senderId: string, input: SendMessageInput): Promise<Message> {
    const result = sendMessageSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { volunteerId, subject, body } = result.data;

    // Verify volunteer exists and get their eventId
    const volunteer = await this.prisma.volunteer.findUnique({
      where: { id: volunteerId },
      select: { id: true, eventId: true },
    });

    if (!volunteer) {
      throw new NotFoundError('Volunteer');
    }

    return this.prisma.message.create({
      data: {
        subject,
        body,
        recipientType: RecipientType.VOLUNTEER,
        recipientId: volunteerId,
        eventId: volunteer.eventId,
        senderId,
        volunteerId,
      },
      include: {
        sender: true,
        volunteer: true,
        event: true,
      },
    });
  }

  /**
   * Send message to all volunteers in a department
   */
  async sendDepartmentMessage(
    senderId: string,
    input: SendDepartmentMessageInput
  ): Promise<Message[]> {
    const result = sendDepartmentMessageSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { departmentId, subject, body } = result.data;

    // Verify department exists and get volunteers
    const department = await this.prisma.department.findUnique({
      where: { id: departmentId },
      include: {
        volunteers: { select: { id: true } },
        event: { select: { id: true } },
      },
    });

    if (!department) {
      throw new NotFoundError('Department');
    }

    if (department.volunteers.length === 0) {
      return [];
    }

    // Create a message for each volunteer in the department
    const messages = await this.prisma.$transaction(
      department.volunteers.map((volunteer) =>
        this.prisma.message.create({
          data: {
            subject,
            body,
            recipientType: RecipientType.DEPARTMENT,
            recipientId: departmentId,
            eventId: department.event.id,
            senderId,
            volunteerId: volunteer.id,
          },
          include: {
            sender: true,
            volunteer: true,
            event: true,
          },
        })
      )
    );

    return messages;
  }

  /**
   * Send broadcast to all volunteers in an event
   */
  async sendBroadcast(senderId: string, input: SendBroadcastInput): Promise<Message[]> {
    const result = sendBroadcastSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { eventId, subject, body } = result.data;

    // Verify event exists and get all volunteers
    const event = await this.prisma.event.findUnique({
      where: { id: eventId },
      include: {
        volunteers: { select: { id: true } },
      },
    });

    if (!event) {
      throw new NotFoundError('Event');
    }

    if (event.volunteers.length === 0) {
      return [];
    }

    // Create a message for each volunteer in the event
    const messages = await this.prisma.$transaction(
      event.volunteers.map((volunteer) =>
        this.prisma.message.create({
          data: {
            subject,
            body,
            recipientType: RecipientType.EVENT,
            recipientId: eventId,
            eventId,
            senderId,
            volunteerId: volunteer.id,
          },
          include: {
            sender: true,
            volunteer: true,
            event: true,
          },
        })
      )
    );

    return messages;
  }

  /**
   * Get messages for a volunteer
   */
  async getVolunteerMessages(
    volunteerId: string,
    filter?: MessageFilterInput,
    limit = 50,
    offset = 0
  ) {
    const where: Prisma.MessageWhereInput = { volunteerId };

    if (filter?.isRead !== undefined) {
      where.isRead = filter.isRead;
    }

    if (filter?.senderId) {
      where.senderId = filter.senderId;
    }

    return this.prisma.message.findMany({
      where,
      include: {
        sender: true,
        event: true,
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset,
    });
  }

  /**
   * Get unread message count for a volunteer
   */
  async getUnreadCount(volunteerId: string): Promise<number> {
    return this.prisma.message.count({
      where: {
        volunteerId,
        isRead: false,
      },
    });
  }

  /**
   * Mark message as read
   */
  async markAsRead(messageId: string, volunteerId: string): Promise<Message> {
    const message = await this.prisma.message.findUnique({
      where: { id: messageId },
    });

    if (!message) {
      throw new NotFoundError('Message');
    }

    if (message.volunteerId !== volunteerId) {
      throw new AuthorizationError('This message does not belong to you');
    }

    if (message.isRead) {
      // Return message with same shape as update branch (including relations)
      return this.prisma.message.findUnique({
        where: { id: messageId },
        include: {
          sender: true,
          event: true,
        },
      }) as Promise<Message>;
    }

    return this.prisma.message.update({
      where: { id: messageId },
      data: {
        isRead: true,
        readAt: new Date(),
      },
      include: {
        sender: true,
        event: true,
      },
    });
  }

  /**
   * Mark all messages as read for a volunteer
   */
  async markAllAsRead(volunteerId: string): Promise<number> {
    const result = await this.prisma.message.updateMany({
      where: {
        volunteerId,
        isRead: false,
      },
      data: {
        isRead: true,
        readAt: new Date(),
      },
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
        sender: true,
        volunteer: true,
        event: true,
      },
    });
  }

  /**
   * Get sent messages for an admin
   */
  async getSentMessages(senderId: string, limit = 50, offset = 0) {
    return this.prisma.message.findMany({
      where: { senderId },
      include: {
        volunteer: true,
        event: true,
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset,
    });
  }

  /**
   * Delete a message (admin only)
   */
  async deleteMessage(messageId: string): Promise<boolean> {
    const message = await this.prisma.message.findUnique({
      where: { id: messageId },
    });

    if (!message) {
      throw new NotFoundError('Message');
    }

    await this.prisma.message.delete({
      where: { id: messageId },
    });

    return true;
  }

  /**
   * Get volunteer's eventId for access control
   */
  async getVolunteerEventId(volunteerId: string): Promise<string> {
    const volunteer = await this.prisma.volunteer.findUnique({
      where: { id: volunteerId },
      select: { eventId: true },
    });

    if (!volunteer) {
      throw new NotFoundError('Volunteer');
    }

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

    if (!department) {
      throw new NotFoundError('Department');
    }

    return department.eventId;
  }
}
