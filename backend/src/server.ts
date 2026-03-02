/**
 * Server Entry Point
 *
 * Main entry point for the application. Sets up Express, Apollo Server,
 * and starts listening for requests.
 *
 * Startup Flow:
 *   1. Configure Express middleware (helmet, cors, json)
 *   2. Set up /health endpoint for AWS ALB health checks
 *   3. Create Apollo Server and attach to /graphql endpoint
 *   4. Start HTTP server on PORT (default 4000)
 *
 * Endpoints:
 *   - GET /health: REST health check (for load balancer)
 *   - POST /graphql: GraphQL API endpoint
 *
 * Environment Variables:
 *   - PORT: Server port (default 4000)
 *   - DATABASE_URL: PostgreSQL connection string
 *   - JWT_SECRET: Access token signing key
 *   - JWT_REFRESH_SECRET: Refresh token signing key
 *
 * Run with: npm run dev (development) or npm start (production)
 */
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import prisma from './config/database.js';
import { createApolloServer } from './graphql/index.js';
import { validateJwtSecrets } from './utils/jwt.js';
import { validateEncryptionKey } from './utils/encryption.js';
import { logger } from './utils/logger.js';

const app = express();
const PORT = process.env.PORT || 4000;

app.use(
  helmet({
    contentSecurityPolicy: process.env.NODE_ENV === 'production' ? undefined : false,
  })
);
// CORS: restrict to environment-based allowlist
const allowedOrigins = (process.env.ALLOWED_ORIGINS || 'http://localhost:3000,http://localhost:4000')
  .split(',')
  .map((o) => o.trim());

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (mobile apps, curl, health checks)
      if (!origin || allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },
  })
);
app.use(express.json());

// Rate limiting on auth-related GraphQL operations
const AUTH_OPERATIONS = new Set([
  'LoginAdmin',
  'RegisterAdmin',
  'LoginVolunteer',
  'RefreshToken',
  'LoginWithGoogle',
  'LoginWithApple',
]);

const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    const operationName = req.body?.operationName;
    return !operationName || !AUTH_OPERATIONS.has(operationName);
  },
  message: { errors: [{ message: 'Too many authentication attempts, please try again later' }] },
});

app.use('/graphql', authRateLimiter);

// General rate limiter: 100 requests per minute per IP
const generalRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { errors: [{ message: 'Too many requests, please try again later' }] },
});

app.use('/graphql', generalRateLimiter);

app.get('/health', async (_req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: { database: 'connected' },
    });
  } catch (error) {
    logger.error('Health check failed', {
      error: error instanceof Error ? error.message : 'Unknown error',
    });
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      services: { database: 'disconnected' },
    });
  }
});

const shutdown = async () => {
  logger.info('Shutting down gracefully...');
  await prisma.$disconnect();
  process.exit(0);
};

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

async function start() {
  validateJwtSecrets();
  validateEncryptionKey();
  const httpServer = await createApolloServer(app);

  httpServer.listen(PORT, () => {
    logger.info('Server started successfully', {
      port: PORT,
      environment: process.env.NODE_ENV || 'development',
      healthCheck: `http://localhost:${PORT}/health`,
      graphql: `http://localhost:${PORT}/graphql`,
    });
  });
}

start().catch((error) => {
  logger.error('Failed to start server', {
    error: error instanceof Error ? error.message : 'Unknown error',
    stack: error instanceof Error ? error.stack : undefined,
  });
  process.exit(1);
});

export default app;
