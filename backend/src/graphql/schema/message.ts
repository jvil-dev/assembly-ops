/**
 * Message Schema
 *
 * GraphQL type definitions for bi-directional messaging operations.
 *
 * Queries:
 *   - message(id): Get message by ID (any auth)
 *   - sentMessages: Get messages sent by admin
 *   - myMessages: Get inbox for any user (admin or volunteer)
 *   - unreadMessageCount: Get unread count for any user
 *   - myConversations: Get conversation threads for any user
 *   - conversationMessages: Get messages in a thread
 *   - searchMessages: Full-text search on messages
 *
 * Mutations:
 *   - sendMessage: Send to individual (any user)
 *   - sendDepartmentMessage: Broadcast to department (admin)
 *   - sendBroadcast: Broadcast to entire event (event overseer)
 *   - sendMultiMessage: Send to multiple volunteers (admin)
 *   - startConversation: Create DM thread between two users
 *   - sendConversationMessage: Reply in a thread
 *   - markMessageRead: Mark single message as read (any user)
 *   - markAllMessagesRead: Mark all as read (any user)
 *   - deleteMessage: Soft delete a message (any user)
 *   - markConversationRead: Mark thread read for user
 *   - deleteConversation: Soft delete thread for user
 */
const messageTypeDefs = `#graphql
  # ============================================
  # INPUTS
  # ============================================

  input SendMessageInput {
    volunteerId: ID
    recipientType: MessageSenderType
    recipientId: ID
    eventId: ID
    subject: String
    body: String!
  }

  input SendDepartmentMessageInput {
    departmentId: ID!
    subject: String
    body: String!
  }

  input SendBroadcastInput {
    eventId: ID!
    subject: String
    body: String!
  }

  input SendMultiMessageInput {
    volunteerIds: [ID!]!
    subject: String
    body: String!
    eventId: ID!
  }

  input StartConversationInput {
    eventId: ID!
    recipientType: MessageSenderType!
    recipientId: ID!
    subject: String
    body: String!
  }

  input SendConversationMessageInput {
    conversationId: ID!
    body: String!
  }

  input MessageFilterInput {
    isRead: Boolean
    senderId: ID
    senderType: MessageSenderType
    recipientType: RecipientType
    search: String
  }

  # ============================================
  # TYPES
  # ============================================

  type MessageCount {
    count: Int!
  }

  type MarkAllReadResult {
    markedCount: Int!
  }

  # ============================================
  # TYPES (messaging-specific)
  # ============================================

  type EventParticipant {
    id: ID!
    displayName: String!
    isAdmin: Boolean!
  }

  # ============================================
  # QUERIES & MUTATIONS
  # ============================================

  extend type Query {
    # Any authenticated user
    message(id: ID!): Message
    myMessages(filter: MessageFilterInput, limit: Int, offset: Int): [Message!]!
    unreadMessageCount: Int!
    myConversations(eventId: ID!, limit: Int, offset: Int): [Conversation!]!
    conversationMessages(conversationId: ID!, limit: Int, offset: Int): [Message!]!
    searchMessages(eventId: ID!, query: String!, limit: Int, offset: Int): [Message!]!
    eventParticipants(eventId: ID!): [EventParticipant!]!

    # Admin only
    sentMessages(limit: Int, offset: Int): [Message!]!
  }

  extend type Mutation {
    # Any authenticated user
    sendMessage(input: SendMessageInput!): Message!
    markMessageRead(id: ID!): Message!
    markAllMessagesRead(eventId: ID): MarkAllReadResult!
    deleteMessage(id: ID!): Boolean!
    startConversation(input: StartConversationInput!): Conversation!
    sendConversationMessage(input: SendConversationMessageInput!): Message!
    markConversationRead(id: ID!): Conversation!
    deleteConversation(id: ID!): Boolean!

    # Admin only
    sendDepartmentMessage(input: SendDepartmentMessageInput!): Conversation!
    sendBroadcast(input: SendBroadcastInput!): Conversation!
    sendMultiMessage(input: SendMultiMessageInput!): [Message!]!
  }

  extend type Subscription {
    messageReceived(eventId: ID!): Message!
    conversationMessageReceived(conversationId: ID!): Message!
    unreadCountUpdated: Int!
  }
`;

export default messageTypeDefs;
