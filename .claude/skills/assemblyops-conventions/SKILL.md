---
name: assemblyops-conventions
description: AssemblyOps codebase conventions and patterns. Covers Prisma service pattern, auth guards, GraphQL schema structure, and the unified User model. Use when writing new services, resolvers, or modifying auth.
user-invocable: false
---

# AssemblyOps Codebase Conventions

## Service Pattern

- Services are **class-based**, taking `PrismaClient` in the constructor — NOT singletons
- Each service file handles one domain (auth, event, volunteer, assignment, etc.)
- Services contain business logic; resolvers are thin wrappers that call services

```typescript
export class MyService {
  constructor(private prisma: PrismaClient) {}
  // methods here
}
```

## Request Flow

```
Request → Express → Apollo Server → context.ts (JWT extraction)
  → Resolver → guard (auth check) → validator (Zod) → Service (business logic + Prisma)
```

## Auth Guards (`src/graphql/guards/auth.ts`)

- `requireUser()` — any authenticated user
- `requireOverseer()` — user.isOverseer === true
- `requireAdmin()` — backward-compat alias for requireOverseer
- `requireAppAdmin()` — user.isAppAdmin === true
- `requireEventAccess(eventId, roles?)` — async, checks EventAdmin membership
- `requireCaptain(eventId)` — async, checks ScheduleAssignment.isCaptain or AreaCaptain
- Guards throw `AuthenticationError` or `AuthorizationError` from `utils/errors.ts`

## GraphQL Schema

- Multi-file: `src/graphql/schema/*.ts` (each exports a gql string)
- Combined in `src/graphql/schema/index.ts` as array
- **Do NOT duplicate types** already in `types.ts` — causes server failures
- Base types: `Query { health: HealthStatus! }`, `Mutation { _empty: String }`, `DateTime` scalar

## Unified User Model

- `Admin` + `VolunteerProfile` merged into `User` with `isOverseer` flag
- Some resolvers still reference `context.admin` (backward-compat alias in context.ts)
- `requireAdmin()` points to `requireOverseer()` — not a separate check

## Database

- PrismaPg adapter with `pg.Pool` for connection pooling (NOT Prisma's built-in pooling)
- Schema: `prisma/schema.prisma` (50+ models)
- Migrations: `prisma/migrations/`

## JWT Tokens

- Access token: 15 minutes, contains `sub` (user ID), `type: 'user'`
- Refresh token: 7 days, stored in `RefreshToken` table with revocation flag
- Extracted in `context.ts` from `Authorization: Bearer <token>` header

## Testing

- Vitest 4.0, forks pool, sequential file execution
- Unit tests: `src/__tests__/unit/*.unit.ts`
- Integration tests: `src/__tests__/integration/*.integration.ts`
- Coverage target: 50% lines/functions/statements
