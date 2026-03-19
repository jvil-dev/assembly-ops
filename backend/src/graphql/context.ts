/**
 * GraphQL Context
 *
 * Created fresh for each request. Identifies the caller via JWT and
 * attaches user info for guards and resolvers to use.
 *
 * Token type: 'user' → logged-in User (volunteer or overseer) → context.user
 */
import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import prisma from '../config/database.js';
import { extractTokenFromHeader, verifyAccessToken } from '../utils/jwt.js';

export interface UserContext {
  id: string;
  userId: string; // 6-char permanent ID
  email: string;
  isOverseer: boolean;
  isAppAdmin: boolean;
}

export interface Context {
  prisma: PrismaClient;
  req?: Request;
  res?: Response;
  user?: UserContext;
  // Legacy alias kept so existing guards/resolvers compile during migration
  admin?: UserContext;
}

export async function createContext({
  req,
  res,
}: {
  req: Request;
  res: Response;
}): Promise<Context> {
  const context: Context = { prisma, req, res };

  const token = extractTokenFromHeader(req.headers.authorization);
  if (!token) return context;

  try {
    const payload = verifyAccessToken(token);

    if (payload.type === 'user') {
      const user = await prisma.user.findUnique({
        where: { id: payload.sub },
        select: { id: true, userId: true, email: true, isOverseer: true, isAppAdmin: true },
      });

      if (user) {
        context.user = user;
        context.admin = user; // backward-compat alias
      }
    }
  } catch {
    // Invalid token — continue without auth context
  }

  return context;
}

/**
 * Create context for WebSocket subscription connections.
 * Extracts JWT from connectionParams.authToken instead of HTTP headers.
 */
export async function createSubscriptionContext(
  connectionParams: Record<string, unknown>
): Promise<Context> {
  const context: Context = { prisma };

  const token = connectionParams?.authToken as string | undefined;
  if (!token) return context;

  try {
    const payload = verifyAccessToken(token);

    if (payload.type === 'user') {
      const user = await prisma.user.findUnique({
        where: { id: payload.sub },
        select: { id: true, userId: true, email: true, isOverseer: true, isAppAdmin: true },
      });

      if (user) {
        context.user = user;
        context.admin = user;
      }
    }
  } catch {
    // Invalid token — continue without auth context
  }

  return context;
}
