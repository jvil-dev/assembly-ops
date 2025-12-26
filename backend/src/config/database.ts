/**
 * Database Configuration
 *
 * Sets up the Prisma client with PostgreSQL connection pooling.
 * Uses the pg library for connection management and PrismaPg adapter.
 *
 * Connection:
 *   - Reads DATABASE_URL from environment variables
 *   - Enables SSL for Supabase/external connections (detected by URL)
 *   - Uses pg.Pool for connection pooling (better performance)
 *
 * Logging:
 *   - Development: Logs queries, errors, warnings
 *   - Production: Only logs errors
 *
 * Supabase Note:
 *   - Port 6543 (pooled): Use for application runtime
 *   - Port 5432 (direct): Use for Prisma migrations
 *
 * Exports: Default prisma client instance used throughout the app
 *
 * Used by: All services, resolvers, and context.ts
 */
import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';

// Enable SSL only for Supabase/external connections
const isExternalDb = process.env.DATABASE_URL?.includes('supabase');

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  ...(isExternalDb && { ssl: { rejectUnauthorized: false } }),
});

const adapter = new PrismaPg(pool);

const prisma = new PrismaClient({
  adapter,
  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
});

export default prisma;
