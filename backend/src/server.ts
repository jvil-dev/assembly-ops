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
import prisma from './config/database.js';
import { createApolloServer } from './graphql/index.js';

const app = express();
const PORT = process.env.PORT || 4000;

app.use(
  helmet({
    contentSecurityPolicy: process.env.NODE_ENV === 'production' ? undefined : false,
  })
);
app.use(cors());
app.use(express.json());

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

const shutdown = async () => {
  console.log('Shutting down gracefully...');
  await prisma.$disconnect();
  process.exit(0);
};

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

async function start() {
  const httpServer = await createApolloServer(app);

  httpServer.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
    console.log(`GraphQL: http://localhost:${PORT}/graphql`);
  });
}

start().catch(console.error);

export default app;
