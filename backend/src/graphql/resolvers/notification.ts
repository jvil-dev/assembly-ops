/**
 * Notification Resolvers
 *
 * GraphQL resolvers for device token registration and notification history.
 *
 * Authorization:
 *   - All operations require authenticated user (requireAuth)
 *
 * Query Resolvers:
 *   - myNotifications: Paginated notification history for an event
 *   - unreadNotificationCount: Count of unread notifications for an event
 *
 * Mutation Resolvers:
 *   - registerDeviceToken: Store/update FCM token for the current user
 *   - unregisterDeviceToken: Remove FCM token (called on logout)
 *   - markNotificationRead: Mark a single notification as read
 *   - markAllNotificationsRead: Mark all notifications for an event as read
 *
 * Used by: ./index.ts (resolver composition)
 */
import { Context } from '../context.js';
import { requireAuth } from '../guards/auth.js';
import { NotificationService } from '../../services/notificationService.js';

const notificationResolvers = {
  Query: {
    myNotifications: async (
      _parent: unknown,
      { eventId, limit, offset }: { eventId: string; limit?: number; offset?: number },
      context: Context
    ) => {
      requireAuth(context);
      const notifications = await context.prisma.notification.findMany({
        where: { userId: context.user!.id, eventId },
        orderBy: { createdAt: 'desc' },
        take: limit || 20,
        skip: offset || 0,
      });
      return notifications.map((n) => ({
        ...n,
        data: n.data ? JSON.stringify(n.data) : null,
      }));
    },

    unreadNotificationCount: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAuth(context);
      return context.prisma.notification.count({
        where: { userId: context.user!.id, eventId, isRead: false },
      });
    },
  },

  Mutation: {
    registerDeviceToken: async (
      _parent: unknown,
      { token, platform }: { token: string; platform?: string },
      context: Context
    ) => {
      requireAuth(context);
      const notificationService = new NotificationService(context.prisma);
      await notificationService.registerToken(context.user!.id, token, platform || 'ios');
      return true;
    },

    unregisterDeviceToken: async (
      _parent: unknown,
      { token }: { token: string },
      context: Context
    ) => {
      requireAuth(context);
      const notificationService = new NotificationService(context.prisma);
      await notificationService.unregisterToken(token);
      return true;
    },

    markNotificationRead: async (
      _parent: unknown,
      { notificationId }: { notificationId: string },
      context: Context
    ) => {
      requireAuth(context);
      await context.prisma.notification.updateMany({
        where: { id: notificationId, userId: context.user!.id },
        data: { isRead: true },
      });
      return true;
    },

    markAllNotificationsRead: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAuth(context);
      await context.prisma.notification.updateMany({
        where: { userId: context.user!.id, eventId, isRead: false },
        data: { isRead: true },
      });
      return true;
    },
  },
};

export default notificationResolvers;
