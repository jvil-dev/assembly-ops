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
