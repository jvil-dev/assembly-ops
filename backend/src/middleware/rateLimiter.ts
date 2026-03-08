/**
 * Sliding Window Counter Rate Limiter
 *
 * In-memory rate limiter using the sliding window counter algorithm.
 * Combines current + previous window counts for smoother rate limiting
 * than fixed window counters.
 *
 * Features:
 *   - Per-user keying for authenticated requests (JWT sub claim)
 *   - IP-based fallback for unauthenticated requests
 *   - Standard RateLimit-* and Retry-After headers
 *   - Periodic cleanup of expired entries to prevent memory leaks
 *   - Operation-based filtering (e.g., auth-only limiting)
 */
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { logger } from '../utils/logger.js';

interface WindowState {
  previousCount: number;
  currentCount: number;
  windowStart: number;
}

interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  resetAt: number;
  limit: number;
}

interface RateLimiterOptions {
  windowMs: number;
  max: number;
  keyPrefix: string;
  /** If set, only applies to these GraphQL operation names. Others are skipped. */
  operations?: string[];
  message?: string;
}

const store = new Map<string, WindowState>();
let cleanupTimer: ReturnType<typeof setInterval> | null = null;

function checkLimit(key: string, max: number, windowMs: number): RateLimitResult {
  const now = Date.now();
  let state = store.get(key);

  if (!state) {
    state = { previousCount: 0, currentCount: 0, windowStart: now };
    store.set(key, state);
  }

  const elapsed = now - state.windowStart;

  // If we've moved past the current window, rotate
  if (elapsed >= windowMs) {
    const windowsPassed = Math.floor(elapsed / windowMs);
    if (windowsPassed === 1) {
      state.previousCount = state.currentCount;
    } else {
      // More than one full window passed — previous is irrelevant
      state.previousCount = 0;
    }
    state.currentCount = 0;
    state.windowStart = state.windowStart + windowsPassed * windowMs;
  }

  // Sliding window estimate
  const elapsedInCurrent = now - state.windowStart;
  const overlapRatio = Math.max(0, (windowMs - elapsedInCurrent) / windowMs);
  const effectiveCount = state.currentCount + state.previousCount * overlapRatio;

  if (effectiveCount >= max) {
    const resetAt = state.windowStart + windowMs;
    return {
      allowed: false,
      remaining: 0,
      resetAt,
      limit: max,
    };
  }

  state.currentCount++;

  const remaining = Math.max(0, Math.floor(max - effectiveCount - 1));
  const resetAt = state.windowStart + windowMs;

  return { allowed: true, remaining, resetAt, limit: max };
}

function extractUserIdFromToken(req: Request): string | null {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) return null;

  try {
    const token = authHeader.slice(7);
    const decoded = jwt.decode(token) as { sub?: string; type?: string } | null;
    if (decoded?.sub && decoded.type === 'user') {
      return decoded.sub;
    }
  } catch {
    // Invalid token — fall back to IP
  }
  return null;
}

function getClientKey(req: Request, prefix: string): string {
  const userId = extractUserIdFromToken(req);
  if (userId) return `${prefix}:user:${userId}`;

  const ip = req.ip || req.socket.remoteAddress || 'unknown';
  return `${prefix}:ip:${ip}`;
}

function cleanupExpiredEntries(maxAge: number): void {
  const now = Date.now();
  let cleaned = 0;
  for (const [key, state] of store) {
    // Entry is expired if both windows have passed
    if (now - state.windowStart > maxAge * 2) {
      store.delete(key);
      cleaned++;
    }
  }
  if (cleaned > 0) {
    logger.debug(
      `Rate limiter cleanup: removed ${cleaned} expired entries, ${store.size} remaining`
    );
  }
}

export function createRateLimiter(options: RateLimiterOptions) {
  const { windowMs, max, keyPrefix, operations, message } = options;
  const errorMessage = message || 'Too many requests, please try again later';

  // Start cleanup interval on first limiter creation (shared across all limiters)
  if (!cleanupTimer) {
    cleanupTimer = setInterval(() => cleanupExpiredEntries(windowMs), 5 * 60 * 1000);
    cleanupTimer.unref(); // Don't prevent process exit
  }

  return (req: Request, res: Response, next: NextFunction): void => {
    // Skip if operations filter is set and this operation doesn't match
    if (operations) {
      const operationName = req.body?.operationName;
      if (!operationName || !operations.includes(operationName)) {
        next();
        return;
      }
    }

    const key = getClientKey(req, keyPrefix);
    const result = checkLimit(key, max, windowMs);

    // Always set standard rate limit headers
    res.setHeader('RateLimit-Limit', result.limit);
    res.setHeader('RateLimit-Remaining', result.remaining);
    res.setHeader('RateLimit-Reset', Math.ceil(result.resetAt / 1000));

    if (!result.allowed) {
      const retryAfter = Math.ceil((result.resetAt - Date.now()) / 1000);
      res.setHeader('Retry-After', Math.max(1, retryAfter));
      res.status(429).json({
        errors: [{ message: errorMessage }],
      });
      return;
    }

    next();
  };
}

/** Clear cleanup timer on shutdown to prevent timer leaks. */
export function shutdownRateLimiter(): void {
  if (cleanupTimer) {
    clearInterval(cleanupTimer);
    cleanupTimer = null;
  }
}
