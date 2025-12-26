# AssemblyOps

A volunteer scheduling and management system for Jehovah's Witnesses assembly and convention committees. Enables overseers to create events, manage departments, assign volunteers to posts across multiple sessions, and track attendance in real-time.

## Why This Project?

Large religious events with 1,000+ attendees require coordinating hundreds of volunteers across multiple departments and time slots. Currently, organizers rely on fragmented tools — Word documents, spreadsheets, group chats — each overseer doing things their own way.

AssemblyOps streamlines this by providing a unified platform for event scheduling, volunteer management, and real-time attendance tracking.

**Why GraphQL?** Mobile apps on unreliable venue WiFi need to minimize network calls. A volunteer's dashboard requires nested data (assignments, sessions, posts, departments) — REST would need 5-6 round trips, GraphQL does it in one request.

## Tech Stack

| Layer          | Technology                                   |
| -------------- | -------------------------------------------- |
| API            | Node.js, Express, Apollo Server, GraphQL     |
| Database       | PostgreSQL with Prisma ORM                   |
| Auth           | JWT (access + refresh tokens)                |
| Validation     | Zod runtime schemas                          |
| Infrastructure | AWS ECS Fargate, Supabase (managed Postgres) |
| CI/CD          | GitHub Actions                               |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Clients                              │
│              (iOS App, Admin Dashboard)                     │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    AWS ALB (HTTPS)                          │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                 ECS Fargate Service                         │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Node.js + Apollo Server                  │  │
│  │                                                       │  │
│  │   Express → Apollo → Resolvers → Services → Prisma    │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│              Supabase (Managed PostgreSQL)                  │
│                   with PgBouncer pooling                    │
└─────────────────────────────────────────────────────────────┘
```

## User Roles

| Role                | Access Level                |
| ------------------- | --------------------------- |
| Event Overseer      | Full access to entire event |
| Department Overseer | Department-scoped access    |
| Volunteer           | Own assignments only        |

## Convention Departments

Accounts, Attendant, Audio/Video, Baptism, Cleaning, First Aid, Information & Volunteer Service, Installation, Lost & Found/Checkroom, Parking, Rooming, Trucking & Equipment

## Project Structure

```
AssemblyOps/
├── backend/           # Node.js GraphQL API
├── docs/              # Architecture & development docs
└── .github/           # CI/CD workflows
```

## Getting Started

See [backend/README.md](./backend/README.md) for setup instructions.

## Development Status

**Current Phase:** Backend Scheduling (Posts, Sessions, Assignments)

| Phase                       | Status      |
| --------------------------- | ----------- |
| Phase 0: DevOps Setup       | ✅ Complete |
| Phase 1: Backend Core       | ✅ Complete |
| Phase 2: Backend Scheduling | In Progress |
| Phase 3: iOS App            | Not Started |
| Phase 4: Backend Operations | Not Started |
| Phase 5: Admin Dashboard    | Not Started |

## License

Private - All rights reserved.
