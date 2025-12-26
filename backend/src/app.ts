/**
 * Express Application Setup
 *
 * Configures the Express app with middleware and health check endpoint.
 * This file sets up the base Express app without starting the server.
 *
 * Middleware:
 *   - helmet: Security headers (CSP, HSTS, X-Frame-Options, etc.)
 *   - cors: Cross-Origin Resource Sharing (allows requests from any origin)
 *   - express.json: Parses JSON request bodies
 *
 * Endpoints:
 *   - GET /health: Health check for AWS ALB (returns 200 if DB connected)
 *
 * Graceful Shutdown:
 *   - Listens for SIGTERM/SIGINT signals
 *   - Disconnects Prisma client before exiting
 *   - Prevents orphaned database connections
 *
 * Note: This file may be redundant with server.ts - consider consolidating.
 *
 * Used by: server.ts (imports and extends this app)
 */
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import prisma from './config/database.js';

const app = express();

// Middleware
app.use(
  helmet({
    contentSecurityPolicy: process.env.NODE_ENV === 'production' ? undefined : false,
  })
);
app.use(cors());
app.use(express.json());

// REST health check (for ALB)
app.get('/health', async (_req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: { database: 'connected' },
    });
  } catch (error) {
    console.error('Health check failed:', error);
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      services: { database: 'disconnected' },
    });
  }
});

// Graceful shutdown
const shutdown = async () => {
  console.log('Shutting down gracefully...');
  await prisma.$disconnect();
  process.exit(0);
};

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

export default app;
