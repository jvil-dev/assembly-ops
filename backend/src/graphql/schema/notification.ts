/**
 * Notification GraphQL Schema
 *
 * Device token registration and notification history.
 *
 * Queries:
 *   - myNotifications: Paginated notification history for an event
 *   - unreadNotificationCount: Count of unread notifications for an event
 *
 * Mutations:
 *   - registerDeviceToken: Store FCM token for the authenticated user
 *   - unregisterDeviceToken: Remove FCM token (on logout)
 *   - markNotificationRead: Mark a single notification as read
 *   - markAllNotificationsRead: Mark all notifications for an event as read
 *
 * Used by: ../schema/index.ts
 */
const notificationTypeDefs = `#graphql
  type Notification {
    id: ID!
    type: String!
    title: String!
    body: String!
    data: String
    isRead: Boolean!
    createdAt: DateTime!
  }

  extend type Query {
    myNotifications(eventId: ID!, limit: Int, offset: Int): [Notification!]!
    unreadNotificationCount(eventId: ID!): Int!
  }

  extend type Mutation {
    registerDeviceToken(token: String!, platform: String): Boolean!
    unregisterDeviceToken(token: String!): Boolean!
    markNotificationRead(notificationId: ID!): Boolean!
    markAllNotificationsRead(eventId: ID!): Boolean!
    deleteNotification(notificationId: ID!): Boolean!
  }
`;

export default notificationTypeDefs;
