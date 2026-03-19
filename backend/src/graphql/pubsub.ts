/**
 * PubSub Singleton
 *
 * In-memory PubSub for GraphQL subscriptions.
 * Suitable for single-instance deployment. For multi-instance,
 * replace with Redis-backed PubSub (e.g., graphql-redis-subscriptions).
 *
 * Used by: resolvers/message.ts, services/messageService.ts
 */
import { PubSub } from 'graphql-subscriptions';

export const pubsub = new PubSub();

// Event name constants
export const MESSAGE_RECEIVED = 'MESSAGE_RECEIVED';
export const CONVERSATION_MESSAGE_RECEIVED = 'CONVERSATION_MESSAGE_RECEIVED';
export const UNREAD_COUNT_UPDATED = 'UNREAD_COUNT_UPDATED';
