/**
 * MessageService Unit Tests
 *
 * Tests the core messaging business logic: direct messages, department
 * broadcasts, event broadcasts, conversation threads, and read receipts.
 * Prisma is mocked via createPrismaMock() — no database required.
 *
 * Coverage:
 *   - sendMessage (validation, self-messaging, USER path, VOLUNTEER path)
 *   - sendDepartmentMessage (not-found, empty dept, happy path)
 *   - sendBroadcast (not-found, empty event, happy path)
 *   - markAsRead (not-found, wrong owner, already-read, happy path)
 *   - startConversation (self-conversation, existing thread, new thread)
 *   - sendConversationMessage (not-found, not-participant)
 *   - getConversationMessages (not-participant)
 */
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { createPrismaMock } from '../unitTestHelpers.js';
import { MessageService } from '../../services/messageService.js';
import { NotFoundError, ValidationError, AuthorizationError } from '../../utils/errors.js';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makeMessage(overrides: Record<string, unknown> = {}) {
  return {
    id: 'msg-1',
    subject: 'Test Subject',
    body: 'Test body content',
    recipientType: 'USER',
    recipientId: 'user-2',
    eventId: 'event-1',
    senderType: 'USER',
    senderUserId: 'user-1',
    senderVolId: null,
    eventVolunteerId: null,
    conversationId: null,
    isRead: false,
    readAt: null,
    deletedBySender: false,
    deletedByRecipient: false,
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    updatedAt: new Date('2026-01-01T00:00:00.000Z'),
    senderUser: null,
    event: null,
    ...overrides,
  };
}

function makeEventVolunteer(overrides: Record<string, unknown> = {}) {
  return {
    id: 'ev-1',
    eventId: 'event-1',
    userId: 'user-2',
    departmentId: 'dept-1',
    ...overrides,
  };
}

function makeConversation(overrides: Record<string, unknown> = {}) {
  return {
    id: 'conv-1',
    eventId: 'event-1',
    subject: 'Conversation Subject',
    updatedAt: new Date('2026-01-01T00:00:00.000Z'),
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    participants: [],
    messages: [],
    ...overrides,
  };
}

function makeParticipant(overrides: Record<string, unknown> = {}) {
  return {
    id: 'part-1',
    conversationId: 'conv-1',
    participantType: 'USER',
    participantId: 'user-1',
    lastReadAt: null,
    deletedAt: null,
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('MessageService', () => {
  let prisma: ReturnType<typeof createPrismaMock>;
  let service: MessageService;

  // Shared sender used throughout (USER type)
  const sender = { senderType: 'USER' as const, senderId: 'user-1' };

  beforeEach(() => {
    vi.clearAllMocks();
    prisma = createPrismaMock();
    service = new MessageService(prisma);
  });

  // -------------------------------------------------------------------------
  // sendMessage
  // -------------------------------------------------------------------------

  describe('sendMessage', () => {
    it('throws ValidationError when body is empty', async () => {
      await expect(
        service.sendMessage(sender, { subject: null, body: '' }, 'event-1')
      ).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when sender tries to message themselves (USER recipient)', async () => {
      await expect(
        service.sendMessage(
          sender,
          { subject: null, body: 'Hello', recipientType: 'USER', recipientId: 'user-1' },
          'event-1'
        )
      ).rejects.toThrow(ValidationError);
    });

    it('throws NotFoundError when USER recipient does not exist', async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValue(null);

      await expect(
        service.sendMessage(
          sender,
          { subject: null, body: 'Hello', recipientType: 'USER', recipientId: 'user-2' },
          'event-1'
        )
      ).rejects.toThrow(NotFoundError);

      expect(prisma.user.findUnique).toHaveBeenCalledOnce();
    });

    it('happy path — USER recipient: creates message with recipientType=USER', async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValue({ id: 'user-2' } as never);
      const created = makeMessage({ recipientType: 'USER', recipientId: 'user-2' });
      vi.mocked(prisma.message.create).mockResolvedValue(created as never);

      const result = await service.sendMessage(
        sender,
        { subject: null, body: 'Hello', recipientType: 'USER', recipientId: 'user-2' },
        'event-1'
      );

      expect(result).toEqual(created);
      expect(prisma.message.create).toHaveBeenCalledOnce();

      const { data } = vi.mocked(prisma.message.create).mock.calls[0][0] as {
        data: Record<string, unknown>;
      };
      expect(data.recipientType).toBe('USER');
      expect(data.recipientId).toBe('user-2');
      expect(data.senderUserId).toBe('user-1');
      expect(data.senderVolId).toBeNull();
    });

    it('throws NotFoundError when VOLUNTEER recipient (eventVolunteer) does not exist', async () => {
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(null);

      await expect(
        service.sendMessage(
          sender,
          { subject: null, body: 'Hello', recipientType: 'VOLUNTEER', recipientId: 'ev-99' },
          'event-1'
        )
      ).rejects.toThrow(NotFoundError);

      expect(prisma.eventVolunteer.findUnique).toHaveBeenCalledOnce();
    });

    it('happy path — VOLUNTEER recipient: creates message with correct sender fields', async () => {
      const ev = makeEventVolunteer({ id: 'ev-1', eventId: 'event-1' });
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(ev as never);
      const created = makeMessage({
        recipientType: 'VOLUNTEER',
        recipientId: 'ev-1',
        eventVolunteerId: 'ev-1',
        senderUserId: 'user-1',
        senderVolId: null,
      });
      vi.mocked(prisma.message.create).mockResolvedValue(created as never);

      const result = await service.sendMessage(
        sender,
        { subject: null, body: 'Hello', recipientType: 'VOLUNTEER', recipientId: 'ev-1' },
        'event-1'
      );

      expect(result).toEqual(created);

      const { data } = vi.mocked(prisma.message.create).mock.calls[0][0] as {
        data: Record<string, unknown>;
      };
      expect(data.recipientType).toBe('VOLUNTEER');
      expect(data.recipientId).toBe('ev-1');
      expect(data.eventVolunteerId).toBe('ev-1');
      expect(data.senderType).toBe('USER');
      expect(data.senderUserId).toBe('user-1');
      expect(data.senderVolId).toBeNull();
    });
  });

  // -------------------------------------------------------------------------
  // sendDepartmentMessage
  // -------------------------------------------------------------------------

  describe('sendDepartmentMessage', () => {
    it('throws NotFoundError when department does not exist', async () => {
      vi.mocked(prisma.department.findUnique).mockResolvedValue(null);

      await expect(
        service.sendDepartmentMessage(sender, {
          departmentId: 'dept-99',
          subject: null,
          body: 'Dept broadcast',
        })
      ).rejects.toThrow(NotFoundError);
    });

    it('happy path — creates conversation and single message for department broadcast', async () => {
      vi.mocked(prisma.department.findUnique).mockResolvedValue({
        id: 'dept-1',
        name: 'Attendant',
        eventVolunteers: [
          { id: 'ev-1', userId: 'user-2' },
          { id: 'ev-2', userId: 'user-3' },
        ],
        event: { id: 'event-1' },
      } as never);

      // No existing broadcast conversation
      vi.mocked(prisma.conversation.findFirst).mockResolvedValue(null);

      // Create new conversation
      vi.mocked(prisma.conversation.create).mockResolvedValue({
        id: 'conv-broadcast-1',
        eventId: 'event-1',
        type: 'DEPARTMENT_BROADCAST',
        departmentId: 'dept-1',
        participants: [],
      } as never);

      // createMany for participants
      vi.mocked(prisma.conversationParticipant.createMany).mockResolvedValue({ count: 3 } as never);

      // Single message created
      const msg = makeMessage({ id: 'msg-1', recipientType: 'DEPARTMENT', conversationId: 'conv-broadcast-1' });
      vi.mocked(prisma.message.create).mockResolvedValue(msg as never);

      // Update conversation updatedAt
      vi.mocked(prisma.conversation.update).mockResolvedValue({} as never);

      // Update sender lastReadAt
      vi.mocked(prisma.conversationParticipant.updateMany).mockResolvedValue({ count: 1 } as never);

      // Final findUnique to return conversation
      vi.mocked(prisma.conversation.findUnique).mockResolvedValue({
        id: 'conv-broadcast-1',
        type: 'DEPARTMENT_BROADCAST',
        participants: [],
        messages: [msg],
      } as never);

      const result = await service.sendDepartmentMessage(sender, {
        departmentId: 'dept-1',
        subject: 'Dept Subject',
        body: 'Dept body',
      });

      expect(result).toBeDefined();
      expect(prisma.conversation.create).toHaveBeenCalledOnce();
      expect(prisma.conversationParticipant.createMany).toHaveBeenCalledOnce();
      expect(prisma.message.create).toHaveBeenCalledOnce();
    });
  });

  // -------------------------------------------------------------------------
  // sendBroadcast
  // -------------------------------------------------------------------------

  describe('sendBroadcast', () => {
    it('throws NotFoundError when event does not exist', async () => {
      vi.mocked(prisma.event.findUnique).mockResolvedValue(null);

      await expect(
        service.sendBroadcast(sender, { eventId: 'event-99', subject: null, body: 'Broadcast' })
      ).rejects.toThrow(NotFoundError);
    });

    it('happy path — creates conversation and single message for event broadcast', async () => {
      vi.mocked(prisma.event.findUnique).mockResolvedValue({
        id: 'event-1',
        eventVolunteers: [
          { id: 'ev-1', userId: 'user-2' },
          { id: 'ev-2', userId: 'user-3' },
        ],
      } as never);

      // No existing broadcast conversation
      vi.mocked(prisma.conversation.findFirst).mockResolvedValue(null);

      // Create new conversation
      vi.mocked(prisma.conversation.create).mockResolvedValue({
        id: 'conv-broadcast-2',
        eventId: 'event-1',
        type: 'EVENT_BROADCAST',
        participants: [],
      } as never);

      // createMany for participants
      vi.mocked(prisma.conversationParticipant.createMany).mockResolvedValue({ count: 3 } as never);

      // Single message created
      const msg = makeMessage({ id: 'msg-1', recipientType: 'EVENT', conversationId: 'conv-broadcast-2' });
      vi.mocked(prisma.message.create).mockResolvedValue(msg as never);

      // Update conversation updatedAt
      vi.mocked(prisma.conversation.update).mockResolvedValue({} as never);

      // Update sender lastReadAt
      vi.mocked(prisma.conversationParticipant.updateMany).mockResolvedValue({ count: 1 } as never);

      // Final findUnique to return conversation
      vi.mocked(prisma.conversation.findUnique).mockResolvedValue({
        id: 'conv-broadcast-2',
        type: 'EVENT_BROADCAST',
        participants: [],
        messages: [msg],
      } as never);

      const result = await service.sendBroadcast(sender, {
        eventId: 'event-1',
        subject: 'Event Broadcast',
        body: 'Broadcast body',
      });

      expect(result).toBeDefined();
      expect(prisma.conversation.create).toHaveBeenCalledOnce();
      expect(prisma.conversationParticipant.createMany).toHaveBeenCalledOnce();
      expect(prisma.message.create).toHaveBeenCalledOnce();
    });
  });

  // -------------------------------------------------------------------------
  // markAsRead
  // -------------------------------------------------------------------------

  describe('markAsRead', () => {
    it('throws NotFoundError when message does not exist', async () => {
      vi.mocked(prisma.message.findUnique).mockResolvedValue(null);

      await expect(service.markAsRead('msg-99', sender)).rejects.toThrow(NotFoundError);
    });

    it('throws AuthorizationError when USER-type message has a different recipientId', async () => {
      const msg = makeMessage({
        recipientType: 'USER',
        recipientId: 'user-other', // not sender.senderId ('user-1')
        eventVolunteerId: null,
      });
      vi.mocked(prisma.message.findUnique).mockResolvedValue(msg as never);

      await expect(service.markAsRead('msg-1', sender)).rejects.toThrow(AuthorizationError);

      // Should not attempt to look up an eventVolunteer since eventVolunteerId is null
      expect(prisma.eventVolunteer.findUnique).not.toHaveBeenCalled();
    });

    it('returns existing message without update when already read', async () => {
      const msg = makeMessage({
        recipientType: 'USER',
        recipientId: 'user-1',
        isRead: true,
        readAt: new Date('2026-01-02T00:00:00.000Z'),
      });
      vi.mocked(prisma.message.findUnique).mockResolvedValue(msg as never);

      const readMsg = { ...msg, senderUser: null, event: null };
      // Second findUnique call (for include) returns the read message
      vi.mocked(prisma.message.findUnique)
        .mockResolvedValueOnce(msg as never) // first: existence check
        .mockResolvedValueOnce(readMsg as never); // second: re-fetch with include

      await service.markAsRead('msg-1', sender);

      expect(prisma.message.update).not.toHaveBeenCalled();
    });

    it('happy path — updates isRead=true and sets readAt for the correct recipient', async () => {
      const msg = makeMessage({
        recipientType: 'USER',
        recipientId: 'user-1',
        isRead: false,
      });
      vi.mocked(prisma.message.findUnique).mockResolvedValue(msg as never);

      const updatedMsg = makeMessage({ isRead: true, readAt: new Date() });
      vi.mocked(prisma.message.update).mockResolvedValue(updatedMsg as never);

      const result = await service.markAsRead('msg-1', sender);

      expect(result).toEqual(updatedMsg);
      expect(prisma.message.update).toHaveBeenCalledOnce();

      const { data } = vi.mocked(prisma.message.update).mock.calls[0][0] as {
        data: Record<string, unknown>;
      };
      expect(data.isRead).toBe(true);
      expect(data.readAt).toBeInstanceOf(Date);
    });
  });

  // -------------------------------------------------------------------------
  // startConversation
  // -------------------------------------------------------------------------

  describe('startConversation', () => {
    it('throws ValidationError when sender tries to start a conversation with themselves', async () => {
      await expect(
        service.startConversation(sender, {
          eventId: 'event-1',
          recipientType: 'USER',
          recipientId: 'user-1', // same as sender.senderId
          subject: null,
          body: 'Hello me',
        })
      ).rejects.toThrow(ValidationError);
    });

    it('un-deletes sender participant and sends message in existing conversation thread', async () => {
      const existingConv = makeConversation({
        id: 'conv-existing',
        participants: [
          makeParticipant({ participantType: 'USER', participantId: 'user-1' }),
          makeParticipant({ id: 'part-2', participantType: 'USER', participantId: 'user-2' }),
        ],
      });

      vi.mocked(prisma.conversation.findFirst).mockResolvedValue(existingConv as never);
      vi.mocked(prisma.conversationParticipant.updateMany).mockResolvedValue({ count: 1 } as never);

      // createConversationMessageInternal internals:
      vi.mocked(prisma.conversationParticipant.findFirst).mockResolvedValue(
        makeParticipant({ participantType: 'USER', participantId: 'user-2' }) as never
      );
      vi.mocked(prisma.message.create).mockResolvedValue(makeMessage() as never);
      vi.mocked(prisma.conversation.update).mockResolvedValue(existingConv as never);

      const returnedConv = { ...existingConv, messages: [makeMessage()] };
      vi.mocked(prisma.conversation.findUnique).mockResolvedValue(returnedConv as never);

      const result = await service.startConversation(sender, {
        eventId: 'event-1',
        recipientType: 'USER',
        recipientId: 'user-2',
        subject: null,
        body: 'Reopening thread',
      });

      expect(result).toEqual(returnedConv);
      // Should un-delete participant, not create a new conversation
      // conversationParticipant.updateMany is called twice:
      //   1. un-delete the sender participant (deletedAt → null)
      //   2. update sender's lastReadAt inside createConversationMessageInternal
      expect(prisma.conversationParticipant.updateMany).toHaveBeenCalledTimes(2);
      const undeleteCall = vi.mocked(prisma.conversationParticipant.updateMany).mock.calls[0][0] as {
        data: Record<string, unknown>;
      };
      expect(undeleteCall.data.deletedAt).toBeNull();
      expect(prisma.conversation.create).not.toHaveBeenCalled();
      expect(prisma.message.create).toHaveBeenCalledOnce();
    });

    it('happy path — creates new Conversation with 2 participants and first message', async () => {
      // No existing conversation
      vi.mocked(prisma.conversation.findFirst).mockResolvedValue(null);

      const newConv = makeConversation({
        id: 'conv-new',
        participants: [
          makeParticipant({ participantType: 'USER', participantId: 'user-1' }),
          makeParticipant({ id: 'part-2', participantType: 'USER', participantId: 'user-2' }),
        ],
      });
      vi.mocked(prisma.conversation.create).mockResolvedValue(newConv as never);

      // createConversationMessageInternal internals:
      vi.mocked(prisma.conversationParticipant.findFirst).mockResolvedValue(
        makeParticipant({ participantType: 'USER', participantId: 'user-2' }) as never
      );
      vi.mocked(prisma.message.create).mockResolvedValue(makeMessage() as never);
      vi.mocked(prisma.conversation.update).mockResolvedValue(newConv as never);

      const returnedConv = { ...newConv, messages: [makeMessage()] };
      vi.mocked(prisma.conversation.findUnique).mockResolvedValue(returnedConv as never);

      const result = await service.startConversation(sender, {
        eventId: 'event-1',
        recipientType: 'USER',
        recipientId: 'user-2',
        subject: 'New Thread',
        body: 'Hello!',
      });

      expect(result).toEqual(returnedConv);
      expect(prisma.conversation.create).toHaveBeenCalledOnce();

      const { data } = vi.mocked(prisma.conversation.create).mock.calls[0][0] as {
        data: Record<string, unknown>;
      };
      // Verify 2 participants are embedded in the create call
      const participantsData = (data.participants as { create: unknown[] }).create;
      expect(participantsData).toHaveLength(2);
      expect(prisma.message.create).toHaveBeenCalledOnce();
    });
  });

  // -------------------------------------------------------------------------
  // sendConversationMessage
  // -------------------------------------------------------------------------

  describe('sendConversationMessage', () => {
    it('throws NotFoundError when conversation does not exist', async () => {
      vi.mocked(prisma.conversation.findUnique).mockResolvedValue(null);

      await expect(
        service.sendConversationMessage(sender, {
          conversationId: 'conv-99',
          body: 'Reply',
        })
      ).rejects.toThrow(NotFoundError);
    });

    it('throws AuthorizationError when sender is not a participant', async () => {
      const conv = makeConversation({
        participants: [
          // Only user-other is a participant, not user-1 (our sender)
          makeParticipant({ participantType: 'USER', participantId: 'user-other' }),
        ],
      });
      vi.mocked(prisma.conversation.findUnique).mockResolvedValue(conv as never);

      await expect(
        service.sendConversationMessage(sender, {
          conversationId: 'conv-1',
          body: 'Unauthorized reply',
        })
      ).rejects.toThrow(AuthorizationError);
    });
  });

  // -------------------------------------------------------------------------
  // getConversationMessages
  // -------------------------------------------------------------------------

  describe('getConversationMessages', () => {
    it('throws AuthorizationError when identity is not a participant', async () => {
      vi.mocked(prisma.conversationParticipant.findFirst).mockResolvedValue(null);

      await expect(
        service.getConversationMessages('conv-1', sender)
      ).rejects.toThrow(AuthorizationError);

      expect(prisma.message.findMany).not.toHaveBeenCalled();
    });
  });
});
