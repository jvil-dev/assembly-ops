/**
 * Prisma Configuration
 *
 * Configuration for Prisma CLI commands (migrate, generate, seed).
 * This file is used by Prisma 7+ for centralized configuration.
 *
 * Settings:
 *   - schema: Path to Prisma schema file
 *   - migrations.path: Where migration files are stored
 *   - migrations.seed: Command to run database seeding
 *   - datasource.url: Database connection string from environment
 *
 * Commands:
 *   - npm run prisma:migrate: Create/run migrations
 *   - npm run prisma:push: Push schema changes (no migration file)
 *   - npm run prisma:generate: Generate Prisma client
 *   - npm run prisma:seed: Run seed script
 *
 * Note: Uses dotenv/config to load .env file for DATABASE_URL
 */
import 'dotenv/config';
import { defineConfig, env } from 'prisma/config';

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
    seed: 'npx tsx prisma/seed.ts',
  },
  datasource: {
    url: env('DATABASE_URL'),
  },
});
