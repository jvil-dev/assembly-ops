/**
 * Notification Service
 *
 * Sends push notifications via Firebase Cloud Messaging (FCM) and persists
 * them to the Notification table for in-app history.
 *
 * Features:
 *   - Multi-device: sends to all registered tokens for a user
 *   - Auto-cleanup: removes stale/invalid FCM tokens on send failure
 *   - Upsert registration: handles device token reassignment on reinstall
 *   - Persistent history: saves each notification to DB for in-app viewing
 *
 * Methods:
 *   - sendToUser(userId, eventId, payload): Send + persist for one user
 *   - sendToUsers(userIds, eventId, payload): Send + persist for multiple users
 *   - registerToken(userId, token, platform): Register/update FCM token
 *   - unregisterToken(token): Remove a single token
 *   - unregisterAllTokens(userId): Remove all tokens for a user (logout)
 *
 * Used by: GraphQL resolvers (assignment, volunteer, attendance)
 */
import { PrismaClient } from '@prisma/client';
import admin from '../config/firebase.js';

export interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

export class NotificationService {
  constructor(private prisma: PrismaClient) {}

  /**
   * Send notification to a single user (all their devices) and persist to DB.
   * Fire-and-forget: logs errors but never throws.
   */
  async sendToUser(userId: string, eventId: string, payload: NotificationPayload): Promise<void> {
    try {
      // Persist notification for in-app history
      await this.prisma.notification.create({
        data: {
          userId,
          eventId,
          type: payload.data?.type || 'GENERAL',
          title: payload.title,
          body: payload.body,
          data: payload.data || {},
        },
      });

      // Guard: Firebase may not be initialized in dev
      if (!admin.apps.length) return;

      const tokens = await this.prisma.deviceToken.findMany({
        where: { userId },
        select: { token: true, id: true },
      });

      if (tokens.length === 0) return;

      const message: admin.messaging.MulticastMessage = {
        tokens: tokens.map((t) => t.token),
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data || {},
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      };

      const response = await admin.messaging().sendEachForMulticast(message);

      // Clean up invalid tokens
      if (response.failureCount > 0) {
        const invalidTokenIds: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (
            !resp.success &&
            resp.error?.code === 'messaging/registration-token-not-registered'
          ) {
            invalidTokenIds.push(tokens[idx].id);
          }
        });
        if (invalidTokenIds.length > 0) {
          await this.prisma.deviceToken.deleteMany({
            where: { id: { in: invalidTokenIds } },
          });
        }
      }
    } catch (error) {
      console.error('Push notification failed', { userId, error });
    }
  }

  /**
   * Send notification to multiple users.
   */
  async sendToUsers(userIds: string[], eventId: string, payload: NotificationPayload): Promise<void> {
    await Promise.allSettled(userIds.map((userId) => this.sendToUser(userId, eventId, payload)));
  }

  // --- Device token management ---

  async registerToken(userId: string, token: string, platform: string = 'ios'): Promise<void> {
    await this.prisma.deviceToken.upsert({
      where: { token },
      create: { userId, token, platform },
      update: { userId, updatedAt: new Date() },
    });
  }

  async unregisterToken(token: string): Promise<void> {
    await this.prisma.deviceToken.deleteMany({
      where: { token },
    });
  }

  async unregisterAllTokens(userId: string): Promise<void> {
    await this.prisma.deviceToken.deleteMany({
      where: { userId },
    });
  }
}
