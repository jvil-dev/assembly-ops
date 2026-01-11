/**
 * Message Schema
 *
 * GraphQL type definitions for messaging operations.
 *
 * Queries:
 *   - message(id): Get message by ID (admin)
 *   - sentMessages: Get messages sent by admin
 *   - myMessages: Get messages for volunteer
 *   - unreadMessageCount: Get unread count for volunteer
 *
 * Mutations:
 *   - sendMessage: Send to individual volunteer
 *   - sendDepartmentMessage: Broadcast to department
 *   - sendBroadcast: Broadcast to entire event
 *   - markMessageRead: Mark single message as read
 *   - markAllMessagesRead: Mark all messages as read
 *   - deleteMessage: Delete a message (admin)
 */
const messageTypeDefs = `#graphql
  # ============================================
  # INPUTS
  # ============================================

  input SendMessageInput {
    volunteerId: ID!
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

  input MessageFilterInput {
    isRead: Boolean
    senderId: ID
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
  # QUERIES & MUTATIONS
  # ============================================

  extend type Query {
    # Admin queries
    message(id: ID!): Message
    sentMessages(limit: Int, offset: Int): [Message!]!
    
    # Volunteer queries
    myMessages(filter: MessageFilterInput, limit: Int, offset: Int): [Message!]!
    unreadMessageCount: Int!
  }

  extend type Mutation {
    # Admin mutations
    sendMessage(input: SendMessageInput!): Message!
    sendDepartmentMessage(input: SendDepartmentMessageInput!): [Message!]!
    sendBroadcast(input: SendBroadcastInput!): [Message!]!
    deleteMessage(id: ID!): Boolean!
    
    # Volunteer mutations
    markMessageRead(id: ID!): Message!
    markAllMessagesRead: MarkAllReadResult!
  }
`;

export default messageTypeDefs;
