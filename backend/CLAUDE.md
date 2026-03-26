# Backend API — CLAUDE.md

Node.js GraphQL API for AssemblyOps. See root `CLAUDE.md` for workflow rules and project overview.

## Commands

```bash
# From backend/
npm run dev              # Dev server with hot reload (tsx watch, port 4000)
npm run build            # Compile TypeScript → dist/
npm start                # Run production build (dist/server.js)
npm test                 # Run Vitest suite once
npm run test:watch       # Tests in watch mode
npm run test:coverage    # Coverage report (target: 50% lines/functions/statements)
npm run lint             # ESLint check
npm run lint:fix         # Auto-fix lint issues
npm run format           # Prettier format

# Prisma
npm run prisma:generate  # Regenerate Prisma client types
npm run prisma:migrate   # Run pending migrations (dev)
npm run prisma:push      # Push schema changes directly (dev only)
npm run prisma:seed      # Seed database via tsx
```

## Tech Stack

- Node.js 20+, TypeScript 5.9
- Express 5.2, Apollo Server 5.2
- Prisma 7.4 with PrismaPg adapter (PostgreSQL 16)
- JWT auth (jsonwebtoken), bcryptjs
- Zod 4.2 for input validation
- Vitest 4.0 for testing
- Firebase Admin (push notifications)
- Google Cloud SDK (Storage, Run, Monitoring, Logging, BigQuery)

## Architecture

```
src/
├── server.ts                    # Express + Apollo startup, rate limiting, health endpoint
├── graphql/
│   ├── index.ts                 # Apollo Server factory (typeDefs + resolvers + context)
│   ├── context.ts               # Per-request context: JWT extraction, prisma client
│   ├── schema/                  # GraphQL type definitions (one file per domain)
│   │   ├── index.ts             # Combines all schema strings
│   │   ├── auth.ts, event.ts, volunteer.ts, assignment.ts, session.ts, post.ts,
│   │   │   message.ts, attendance.ts, area.ts, types.ts, oauth.ts, ...
│   │   └── (31 files total)
│   ├── resolvers/               # Resolver implementations (matches schema files)
│   │   ├── index.ts             # Merges all resolvers (Query, Mutation, Type Resolvers)
│   │   └── (30 files)
│   ├── validators/              # Zod input validation schemas
│   └── guards/
│       └── auth.ts              # Authorization guard functions
├── services/                    # Business logic (class-based, takes PrismaClient in constructor)
│   ├── authService.ts           # Registration, login, token refresh, OAuth
│   ├── eventService.ts          # Event CRUD, department management
│   └── (26 service files total)
├── utils/
│   ├── jwt.ts                   # Token generation/verification (15m access, 7d refresh)
│   ├── password.ts              # bcryptjs hashing
│   ├── encryption.ts            # PII encryption (AES-256-GCM)
│   ├── errors.ts                # AuthenticationError, AuthorizationError, ValidationError, ConflictError
│   └── logger.ts, credentials.ts, ...
├── config/
│   ├── database.ts              # Prisma client with PrismaPg adapter + connection pooling
│   └── firebase.ts              # Firebase Admin SDK
├── middleware/
│   └── rateLimiter.ts           # Sliding window rate limiter (per-user keying)
└── __tests__/
    ├── unit/                    # 9 unit test files
    ├── integration/             # 18 integration test files
    ├── setup.ts
    └── testHelpers.ts, unitTestHelpers.ts
```

### Request Flow

```
Request → Express → Apollo Server → context.ts (JWT extraction)
  → Resolver → guard (auth check) → validator (Zod) → Service (business logic + Prisma)
```

## Auth

### JWT Tokens

- **Access token**: 15 minutes, contains `sub` (user ID), `type: 'user'`
- **Refresh token**: 7 days, stored in `RefreshToken` table with revocation flag
- Extracted in `context.ts` from `Authorization: Bearer <token>` header

### Guard Functions (`src/graphql/guards/auth.ts`)

| Guard                                 | Purpose                                                    |
| ------------------------------------- | ---------------------------------------------------------- |
| `requireUser()`                       | Any authenticated user                                     |
| `requireOverseer()`                   | `user.isOverseer === true` (V1: refactoring to per-department claim check) |
| `requireAdmin()`                      | Backward-compat alias for `requireOverseer`                |
| `requireAppAdmin()`                   | `user.isAppAdmin === true`                                 |
| `requireAuth()`                       | Alias for `requireUser`                                    |
| `requireEventAccess(eventId, roles?)` | Async — checks EventAdmin membership                       |
| `requireCaptain(eventId)`             | Async — checks ScheduleAssignment.isCaptain or AreaCaptain |
| `requireDeptAccess()`                 | Department-level access                                    |
| `requireAreaOverseer()`               | Area-level access                                          |
| `tryRequireAdmin()`                   | Non-throwing boolean check                                 |

Guards throw `AuthenticationError` or `AuthorizationError` (custom error classes in `utils/errors.ts`).

### Context (`src/graphql/context.ts`)

- Creates fresh context per request
- Attaches `user: UserContext` (unified for volunteers + overseers)
- Legacy `admin?: UserContext` alias for backward compatibility
- Includes `prisma` client

## GraphQL Schema

- Multi-file: `src/graphql/schema/*.ts` (each exports a gql string)
- Combined in `src/graphql/schema/index.ts` as array
- Base types: `Query { health: HealthStatus! }`, `Mutation { _empty: String }`, `DateTime` scalar
- Key domains: auth, event, volunteer, assignment, session, post, message, attendance, area, oauth

## Database

- **Schema**: `prisma/schema.prisma` (50+ models)
- **Migrations**: `prisma/migrations/` (22 tracked)
- **Seed**: `prisma/seed.ts` + `prisma/seed/` data files

### Key Models

- **User** — Unified (replaces Admin + VolunteerProfile), `isOverseer` flag (V1: removing global flag, overseer status becomes per-department via claim/purchase), `isAppAdmin` flag
- **Event** — Convention/assembly with departments, sessions
- **EventAdmin** — User as overseer on event (EventRole enum)
- **EventVolunteer** — User participation in event
- **Department** — 15 types per event (V1: adding STAGE), has posts, linked to overseer
- **Post** — Physical positions within department
- **Session** — Time blocks for event
- **ScheduleAssignment** — EventVolunteer + Post + Session + isCaptain

## Testing

- **Framework**: Vitest 4.0 (forks pool, sequential file execution)
- **Unit tests**: `src/__tests__/unit/*.unit.ts`
- **Integration tests**: `src/__tests__/integration/*.integration.ts`
- **Coverage**: 50% lines/functions/statements, 45% branches
- **Coverage scope**: `src/services/`, `src/graphql/guards/auth.ts`

```bash
npm test                                    # All tests
npm test src/__tests__/unit/authService.unit.ts  # Specific file
npm test -- --grep "pattern"                # Filter by name
```

## Environment

### Required

| Variable              | Description                                                         |
| --------------------- | ------------------------------------------------------------------- |
| `DATABASE_URL`        | PostgreSQL connection string (Cloud SQL via Unix socket or TCP)     |
| `DIRECT_URL`          | Direct DB URL for migrations (port 5432)                            |
| `JWT_SECRET`          | Access token signing key (min 32 chars)                             |
| `JWT_REFRESH_SECRET`  | Refresh token signing key (min 32 chars, different from JWT_SECRET) |
| `VOLUNTEER_TOKEN_KEY` | 64-char hex for encryption                                          |
| `PII_ENCRYPTION_KEY`  | 64-char hex for PII encryption                                      |

### Optional

| Variable                                                | Description                      |
| ------------------------------------------------------- | -------------------------------- |
| `PORT`                                                  | Server port (default 4000)       |
| `NODE_ENV`                                              | development / production / test  |
| `ALLOWED_ORIGINS`                                       | CORS allowlist (comma-separated) |
| `GOOGLE_CLIENT_ID`                                      | OAuth — Sign in with Google      |
| `APPLE_CLIENT_ID`                                       | OAuth — Sign in with Apple       |
| `GCS_BUCKET`                                            | GCS floor plans                  |
| `GCP_PROJECT_ID`, `GCP_REGION`, `GCP_CLOUD_RUN_SERVICE` | GCP infrastructure monitoring    |
| `DATABASE_SSL`                                          | Enable SSL for DB connections    |

## Gotchas

- **Unified User model**: `Admin` + `VolunteerProfile` merged into `User` with `isOverseer` flag. Some resolvers still reference `context.admin` (backward-compat alias). **V1 removes the global `isOverseer` flag** — overseer status will be per-department.
- **V1 feature gating**: Departments have three tiers (Free/Standard/Pro). Backend will need middleware to check department purchase status before allowing access to gated features (analytics, messaging, equipment tracking, incident reports).
- **Service pattern**: Class-based, takes `PrismaClient` in constructor — NOT singletons
- **PrismaPg adapter**: Uses `pg.Pool` for connection pooling, not Prisma's built-in pooling
- **`requireAdmin()` is an alias**: Points to `requireOverseer()` — not a separate check
- **Duplicate type defs**: Schema files must not duplicate types already in `types.ts` (causes server failures)
- **`resolveAttendantVolunteer()`**: Bridges both EventVolunteer and legacy Volunteer tokens with dept check
