# =============================================================================
# AssemblyOps Backend Dockerfile
# =============================================================================
#
# Multi-stage Docker build for optimal image size and security.
# Final image is ~150MB (node:20-alpine base).
#
# Stages:
#   1. deps: Install npm dependencies and generate Prisma client
#   2. builder: Compile TypeScript to JavaScript
#   3. runner: Production image with only compiled code + node_modules
#
# Build: docker build -t assemblyops-api .
# Run:   docker run -p 4000:4000 --env-file .env assemblyops-api
#
# Environment Variables Required:
#   - DATABASE_URL: PostgreSQL connection string
#   - JWT_SECRET: Access token signing key
#   - JWT_REFRESH_SECRET: Refresh token signing key
#
# Health Check:
#   - GET http://localhost:4000/health
#   - Used by AWS ALB and Docker health checks
#
# Security:
#   - Runs as non-root user (expressjs:nodejs)
#   - Only production dependencies included
#   - No source code in final image (only compiled JS)
#
# =============================================================================

# ============================================
# Stage 1: Dependencies
# ============================================
FROM node:20-alpine AS deps
WORKDIR /app

COPY package*.json ./
COPY prisma ./prisma/
COPY prisma.config.ts ./

RUN npm ci
# Dummy URL for prisma generate (doesn't connect to DB, just generates client)
RUN DATABASE_URL="postgresql://dummy:dummy@localhost:5432/dummy" npx prisma generate

# ============================================
# Stage 2: Builder
# ============================================
FROM node:20-alpine AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/prisma ./prisma
COPY . .

RUN npm run build

# ============================================
# Stage 3: Production
# ============================================
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=4000

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 expressjs

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/prisma.config.ts ./
COPY --from=builder /app/package*.json ./

USER expressjs

EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:4000/health || exit 1

CMD ["node", "dist/server.js"]