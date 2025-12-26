# AssemblyOps Backend

GraphQL API for the AssemblyOps volunteer scheduling system.

## Tech Stack

- **Runtime:** Node.js 20+
- **Framework:** Express + Apollo Server 4
- **API:** GraphQL with graphql-scalars
- **Database:** PostgreSQL 16 with Prisma ORM
- **Auth:** JWT (access tokens 15min, refresh tokens 7 days)
- **Validation:** Zod 4 runtime schemas
- **Testing:** Jest + Supertest

## Quick Start

### Prerequisites

- Node.js 20+
- PostgreSQL 16+ (or Docker)
- npm

### Setup

```bash
# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your database credentials

# Generate Prisma client
npm run prisma:generate

# Run migrations
npm run prisma:migrate

# Seed the database (event templates)
npm run prisma:seed

# Start development server
npm run dev
```

The GraphQL playground will be available at `http://localhost:4000/graphql`

### Using Docker

```bash
# Start API + PostgreSQL
docker compose up

# In another terminal, run migrations
npm run prisma:migrate
npm run prisma:seed
```

## Environment Variables

```env
DATABASE_URL=postgresql://user:password@localhost:5432/assemblyops
JWT_SECRET=your-secret-key
JWT_REFRESH_SECRET=your-refresh-secret-key
```

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Start dev server with hot reload |
| `npm run build` | Compile TypeScript |
| `npm test` | Run tests |
| `npm run lint` | ESLint check |
| `npm run lint:fix` | Auto-fix lint issues |
| `npm run format` | Prettier format |
| `npm run prisma:migrate` | Run database migrations |
| `npm run prisma:generate` | Regenerate Prisma client |
| `npm run prisma:seed` | Seed database |
| `npm run prisma:push` | Push schema changes (dev only) |

## Project Structure

```
src/
├── graphql/
│   ├── schema/        # GraphQL type definitions
│   ├── resolvers/     # Resolver implementations
│   ├── validators/    # Zod input validation
│   ├── guards/        # Authorization guards
│   ├── context.ts     # Request context
│   └── index.ts       # Apollo Server setup
├── services/          # Business logic
├── utils/             # JWT, password hashing, errors
├── config/            # Database client
├── __tests__/         # Integration tests
├── app.ts             # Express app
└── server.ts          # Entry point
```

## API Overview

### Authentication

```graphql
# Register admin (overseer)
mutation {
  registerAdmin(input: {
    email: "overseer@example.com"
    password: "SecurePass123"
    firstName: "John"
    lastName: "Doe"
    congregation: "Central Congregation"
  }) {
    accessToken
    refreshToken
    admin { id email }
  }
}

# Login
mutation {
  loginAdmin(input: {
    email: "overseer@example.com"
    password: "SecurePass123"
  }) {
    accessToken
    refreshToken
  }
}
```

### Events

```graphql
# Get available event templates
query {
  eventTemplates(serviceYear: 2026) {
    id
    name
    eventType
    startDate
    endDate
  }
}

# Activate an event
mutation {
  activateEvent(input: { templateId: "..." }) {
    id
    joinCode
  }
}
```

### Posts & Sessions

```graphql
# Create posts (volunteer positions)
mutation {
  createPosts(input: {
    departmentId: "..."
    posts: [
      { name: "East Lobby", capacity: 2 }
      { name: "Main Entrance", capacity: 3 }
    ]
  }) {
    id
    name
    capacity
  }
}

# Create sessions (time blocks)
mutation {
  createSessions(input: {
    eventId: "..."
    sessions: [
      { name: "Saturday Morning", date: "2026-03-07T00:00:00Z", startTime: "09:00", endTime: "12:00" }
      { name: "Saturday Afternoon", date: "2026-03-07T00:00:00Z", startTime: "13:30", endTime: "16:30" }
    ]
  }) {
    id
    name
  }
}
```

## Authorization

All requests require `Authorization: Bearer <token>` header.

| Role | Permissions |
|------|-------------|
| EVENT_OVERSEER | Full event access, manage sessions |
| DEPARTMENT_OVERSEER | Department-scoped, manage posts & volunteers |
| VOLUNTEER | View own assignments only |

## Database Schema

See `prisma/schema.prisma` for the full data model. Key entities:

- **Admin** - Overseers (email/password auth)
- **Volunteer** - Workers (generated credentials)
- **Event** - Activated from EventTemplate
- **Department** - One of 12 convention departments
- **Post** - Physical positions within a department
- **Session** - Event-wide time blocks
- **ScheduleAssignment** - Volunteer + Post + Session

## Testing

```bash
# Run all tests
npm test

# Run specific test file
npm test -- --testPathPattern="health"

# Watch mode
npm run test:watch
```

## Deployment

The API deploys to AWS ECS Fargate via GitHub Actions:

- Push to `development` → Deploy to staging
- Push to `main` → Deploy to production

See `.github/workflows/` for CI/CD configuration.
