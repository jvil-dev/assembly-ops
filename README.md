# AssemblyOps

A volunteer scheduling and management system for assembly attendant teams.

AssemblyOps enables attendant overseers to create schedules, assign posts, track check-ins, and communicate with volunteers during assemblies. Built with offline-first architecture for venues with limited connectivity.

![CI](https://github.com/jvil-dev/assembly-ops/actions/workflows/ci.yml/badge.svg)
![Docker](https://github.com/jvil-dev/assembly-ops/actions/workflows/docker.yml/badge.svg)

## Project Structure

```
assembly-ops/
├── .github/workflows/  # CI/CD pipelines
├── backend/            # Node.js/Express API
├── ios-app/            # iOS app (Swift) - Coming Soon
├── android-app/        # Android app (Kotlin) - Coming Soon
└── docs/               # Documentation
```

## Tech Stack

| Layer          | Technology                              |
| -------------- | --------------------------------------- |
| **Backend**    | Node.js 20, Express, TypeScript (ESM)   |
| **Database**   | PostgreSQL 16, Prisma 7 ORM             |
| **Auth**       | JWT with bcrypt password hashing        |
| **Testing**    | Jest, Supertest                         |
| **CI/CD**      | GitHub Actions                          |
| **Containers** | Docker, Docker Compose                  |
| **Registry**   | GitHub Container Registry (ghcr.io)     |
| **iOS**        | Swift, SwiftUI, Core Data — Coming Soon |
| **Android**    | Kotlin, Room — Coming Soon              |

## Features

### Current (Backend Complete)

- **Dual Authentication** — Admins use email/password; volunteers use auto-generated credentials
- **Event Management** — Create circuit assemblies and regional conventions
- **Custom Roles** — Define role hierarchies per event (Overseer, Captain, Attendant, etc.)
- **Volunteer Management** — Search, filter, bulk import, and manage volunteer teams
- **Session Scheduling** — Morning/afternoon sessions with availability tracking
- **Zone Management** — Define coverage areas with capacity requirements
- **Assignment System** — Assign volunteers to zones with conflict detection
- **Swap Requests** — Volunteers request changes; admins approve/deny
- **Check-In/Check-Out** — Real-time attendance tracking with late detection
- **Schedule Views** — Grid view, coverage summaries, and zone status

### Planned

- **Communication Panel** — In-app messaging and quick alerts
- **Offline Sync** — Full offline capability with background sync
- **Reports** — Attendance summaries and exportable reports
- **Mobile Apps** — iOS and Android native applications

## Quick Start

### Prerequisites

- Docker Desktop ([download](https://www.docker.com/products/docker-desktop/))
- Node.js 20+ (for local development without Docker)

### Run with Docker (Recommended)

```bash
# Clone the repository
git clone https://github.com/jvil-dev/assembly-ops.git
cd assembly-ops

# Start development environment
cd backend
npm run docker:dev
```

Backend runs at `http://localhost:3000`

### Run Locally

```bash
cd backend
npm install
cp .env.example .env  # Configure your database URL
npm run prisma:migrate
npm run dev
```

## API Overview

| Resource      | Endpoints | Description                        |
| ------------- | --------- | ---------------------------------- |
| Auth          | 6         | Admin/volunteer login, check-in    |
| Events        | 5         | CRUD for assemblies                |
| Roles         | 4         | Custom roles per event             |
| Volunteers    | 8         | Team management with search/filter |
| Sessions      | 6         | Coverage periods and availability  |
| Zones         | 5         | Physical areas with capacity       |
| Assignments   | 6         | Volunteer scheduling               |
| Swap Requests | 5         | Assignment change workflow         |
| Check-Ins     | 10        | Attendance tracking                |
| Schedule      | 2         | Grid view and summaries            |

**Total: 57 endpoints**

See [Backend API Documentation](./backend/README.md) for full details.

## Development

### Running Tests

```bash
cd backend
npm test              # Run all tests
npm run test:watch    # Watch mode
npm run test:coverage # With coverage report
```

### Code Quality

```bash
npm run lint          # ESLint
npm run type-check    # TypeScript validation
```

### Docker Commands

```bash
npm run docker:dev      # Start dev environment (hot reload)
npm run docker:dev:down # Stop dev environment
npm run docker:build    # Build production image
npm run docker:prod     # Start production environment
```

## CI/CD Pipeline

Every push and pull request triggers:

1. **Lint** — ESLint code quality checks
2. **Type Check** — TypeScript validation
3. **Test** — Jest unit and integration tests

Merges to `main` additionally: 4. **Build** — Multi-stage Docker image 5. **Push** — Deploy to GitHub Container Registry

## Documentation

- [Backend API Reference](./backend/README.md)
- [Database Schema](./backend/prisma/schema.prisma)

## Author

**Jorge Villeda**  
[GitHub](https://github.com/jvil-dev) • [LinkedIn](https://linkedin.com/in/jvilleda-dev)

## License

ISC
