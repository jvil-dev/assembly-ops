# AssemblyOps Backend

Node.js/Express API for the AssemblyOps volunteer management system.

## Tech Stack

- **Runtime:** Node.js 20 (Alpine)
- **Framework:** Express.js
- **Language:** TypeScript (ESM)
- **Database:** PostgreSQL 16 (Supabase or Docker)
- **ORM:** Prisma 7
- **Auth:** JWT with bcrypt password hashing
- **Testing:** Jest, Supertest
- **CI/CD:** GitHub Actions
- **Container:** Docker with multi-stage builds

## Quick Start

### Option 1: Docker (Recommended)

```bash
# Start development environment (backend + PostgreSQL)
npm run docker:dev

# Stop environment
npm run docker:dev:down
```

### Option 2: Local Development

```bash
# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your database URL

# Run database migrations
npm run prisma:migrate

# Start development server
npm run dev
```

Server runs at `http://localhost:3000`

---

## Environment Variables

```env
# Server
NODE_ENV=development
PORT=3000

# Database (Docker)
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/assemblyops"

# Database (Supabase)
# DATABASE_URL="postgresql://postgres:PASSWORD@db.PROJECT.supabase.co:5432/postgres"

# JWT
JWT_SECRET="your-secret-key-change-in-production"
JWT_EXPIRES_IN="7d"
```

---

## Scripts

| Script            | Command                   | Description                        |
| ----------------- | ------------------------- | ---------------------------------- |
| `dev`             | `npm run dev`             | Development server with hot reload |
| `build`           | `npm run build`           | Compile TypeScript                 |
| `start`           | `npm start`               | Run production server              |
| `test`            | `npm test`                | Run all tests                      |
| `test:watch`      | `npm run test:watch`      | Tests in watch mode                |
| `test:coverage`   | `npm run test:coverage`   | Tests with coverage report         |
| `lint`            | `npm run lint`            | Run ESLint                         |
| `lint:fix`        | `npm run lint:fix`        | Fix ESLint issues                  |
| `type-check`      | `npm run type-check`      | TypeScript validation              |
| `docker:dev`      | `npm run docker:dev`      | Start Docker dev environment       |
| `docker:dev:down` | `npm run docker:dev:down` | Stop Docker dev environment        |
| `docker:build`    | `npm run docker:build`    | Build production Docker image      |
| `docker:prod`     | `npm run docker:prod`     | Start production environment       |
| `prisma:generate` | `npm run prisma:generate` | Generate Prisma client             |
| `prisma:migrate`  | `npm run prisma:migrate`  | Run migrations (dev)               |
| `prisma:studio`   | `npm run prisma:studio`   | Visual database browser            |

---

## API Reference

### Authentication

#### Admin Registration

```
POST /auth/admin/register
```

```json
{
  "email": "admin@example.com",
  "password": "password123",
  "name": "Jorge Villeda",
  "congregation": "Southwest Spanish"
}
```

#### Admin Login

```
POST /auth/admin/login
```

```json
{
  "email": "admin@example.com",
  "password": "password123"
}
```

#### Volunteer Login

```
POST /auth/volunteer/login
```

```json
{
  "generatedId": "VOL-A3B7K9",
  "loginToken": "8f3a2b1c4d5e6f7a8b9c0d1e2f3a4b5c"
}
```

#### Get Current Admin

```
GET /auth/admin/me
Authorization: Bearer <admin-token>
```

#### Get Volunteer's Assignments

```
GET /auth/volunteer/my-assignments
Authorization: Bearer <volunteer-token>
```

#### Volunteer Check-In

```
POST /auth/volunteer/check-in
Authorization: Bearer <volunteer-token>
```

Automatically checks in to current active assignment based on session time.

**Response:**

```json
{
  "message": "Checked in successfully",
  "checkIn": {
    "id": "clx...",
    "status": "CHECKED_IN",
    "isLate": false,
    "checkInTime": "2026-03-22T09:18:00.000Z",
    "assignment": { "...": "..." },
    "volunteer": { "...": "..." }
  }
}
```

#### Volunteer Check-Out

```
POST /auth/volunteer/check-out
Authorization: Bearer <volunteer-token>
```

#### Volunteer Status

```
GET /auth/volunteer/my-status
Authorization: Bearer <volunteer-token>
```

Returns current check-in status and upcoming assignments.

---

### Events

All event endpoints require admin authentication.

#### Create Event

```
POST /events
```

```json
{
  "name": "Spring Circuit Assembly 2026",
  "type": "CIRCUIT_ASSEMBLY",
  "location": "Natick Assembly Hall",
  "startDate": "2026-03-22T09:00:00Z",
  "endDate": "2026-03-22T17:00:00Z"
}
```

| Field | Type | Options                                   |
| ----- | ---- | ----------------------------------------- |
| type  | enum | `CIRCUIT_ASSEMBLY`, `REGIONAL_CONVENTION` |

#### List Events

```
GET /events
```

#### Get Event

```
GET /events/:id
```

#### Update Event

```
PUT /events/:id
```

#### Delete Event

```
DELETE /events/:id
```

---

### Roles

Custom roles per event. Nested under events.

#### Create Role

```
POST /events/:eventId/roles
```

```json
{
  "name": "Captain",
  "displayOrder": 1
}
```

#### List Roles

```
GET /events/:eventId/roles
```

#### Update Role

```
PUT /events/:eventId/roles/:roleId
```

#### Delete Role

```
DELETE /events/:eventId/roles/:roleId
```

---

### Volunteers

#### Create Volunteer

```
POST /events/:eventId/volunteers
```

```json
{
  "name": "Manuel Smith",
  "phone": "555-1234",
  "email": "manuel@example.com",
  "congregation": "North Central Spanish",
  "appointment": "MINISTERIAL_SERVANT",
  "roleId": "clx..."
}
```

| Field       | Type | Options                                     |
| ----------- | ---- | ------------------------------------------- |
| appointment | enum | `PUBLISHER`, `MINISTERIAL_SERVANT`, `ELDER` |

#### Bulk Create Volunteers

```
POST /events/:eventId/volunteers/bulk
```

```json
{
  "volunteers": [
    { "name": "Saul Loyal", "congregation": "Springfield English" },
    { "name": "Brandon Rodriguez", "appointment": "ELDER" }
  ]
}
```

_Maximum 100 volunteers per request._

#### List Volunteers (with Search & Filter)

```
GET /events/:eventId/volunteers
```

| Query Param    | Description                                 |
| -------------- | ------------------------------------------- |
| `name`         | Partial match, case-insensitive             |
| `roleId`       | Filter by role ID                           |
| `congregation` | Partial match, case-insensitive             |
| `appointment`  | `PUBLISHER`, `MINISTERIAL_SERVANT`, `ELDER` |
| `sort`         | `name_asc`, `name_desc`, `role_asc`         |
| `limit`        | Max results (default 50, max 100)           |
| `offset`       | Skip results for pagination                 |

Example:

```
GET /events/:eventId/volunteers?congregation=springfield&appointment=ELDER&sort=name_asc&limit=20
```

#### Get Volunteer

```
GET /events/:eventId/volunteers/:volunteerId
```

#### Update Volunteer

```
PUT /events/:eventId/volunteers/:volunteerId
```

#### Delete Volunteer

```
DELETE /events/:eventId/volunteers/:volunteerId
```

#### Regenerate Credentials

```
POST /events/:eventId/volunteers/:volunteerId/regenerate
```

---

### Sessions

Morning/afternoon coverage periods per event.

#### Create Session

```
POST /events/:eventId/sessions
```

```json
{
  "name": "Morning Session",
  "date": "2026-03-22T00:00:00Z",
  "startTime": "2026-03-22T09:20:00Z",
  "endTime": "2026-03-22T12:00:00Z"
}
```

#### List Sessions

```
GET /events/:eventId/sessions
```

#### Get Session

```
GET /events/:eventId/sessions/:sessionId
```

#### Update Session

```
PUT /events/:eventId/sessions/:sessionId
```

#### Delete Session

```
DELETE /events/:eventId/sessions/:sessionId
```

#### Get Available Volunteers for Session

```
GET /events/:eventId/sessions/:sessionId/available-volunteers
```

---

### Volunteer Availability

Track which sessions each volunteer can work.

#### Get Volunteer Availability

```
GET /events/:eventId/volunteers/:volunteerId/availability
```

#### Set Volunteer Availability

```
PUT /events/:eventId/volunteers/:volunteerId/availability
```

```json
{
  "availability": [
    { "sessionId": "clx...", "isAvailable": true },
    { "sessionId": "clx...", "isAvailable": false }
  ]
}
```

---

### Zones

Physical areas requiring attendant coverage (e.g., East Lobby, Auditorium).

#### Create Zone

```
POST /events/:eventId/zones
```

```json
{
  "name": "East Lobby",
  "description": "Main entrance on east side",
  "requiredCount": 2,
  "displayOrder": 0
}
```

#### List Zones

```
GET /events/:eventId/zones
```

#### Get Zone

```
GET /events/:eventId/zones/:zoneId
```

#### Update Zone

```
PUT /events/:eventId/zones/:zoneId
```

#### Delete Zone

```
DELETE /events/:eventId/zones/:zoneId
```

---

### Assignments

Assign volunteers to zone + session combinations.

#### Create Assignment

```
POST /events/:eventId/assignments
```

```json
{
  "volunteerId": "clx...",
  "sessionId": "clx...",
  "zoneId": "clx...",
  "notes": "Please arrive 10 minutes early"
}
```

**Conflict Detection:**

- Returns `409` if volunteer is unavailable for the session
- Returns `409` if volunteer is already assigned to another zone in the same session

#### Bulk Create Assignments

```
POST /events/:eventId/assignments/bulk
```

```json
{
  "assignments": [
    { "volunteerId": "clx...", "sessionId": "clx...", "zoneId": "clx..." },
    { "volunteerId": "clx...", "sessionId": "clx...", "zoneId": "clx..." }
  ]
}
```

_Maximum 100 assignments per request._

#### List All Assignments

```
GET /events/:eventId/assignments
```

#### Get Assignments by Session

```
GET /events/:eventId/assignments/by-session/:sessionId
```

#### Get Assignments by Zone

```
GET /events/:eventId/assignments/by-zone/:zoneId
```

#### Delete Assignment

```
DELETE /events/:eventId/assignments/:assignmentId
```

---

### Swap Requests

Volunteers request assignment changes, admin approves or denies.

#### Create Swap Request

```
POST /events/:eventId/swap-requests
```

```json
{
  "assignmentId": "clx...",
  "reason": "Family emergency - need to leave early",
  "suggestedVolunteerId": "clx..."
}
```

#### List Swap Requests

```
GET /events/:eventId/swap-requests
GET /events/:eventId/swap-requests?status=PENDING
```

| Query Param | Options                         |
| ----------- | ------------------------------- |
| `status`    | `PENDING`, `APPROVED`, `DENIED` |

#### Get Swap Request

```
GET /events/:eventId/swap-requests/:requestId
```

#### Approve Swap Request

```
PUT /events/:eventId/swap-requests/:requestId/approve
```

#### Deny Swap Request

```
PUT /events/:eventId/swap-requests/:requestId/deny
```

---

### Schedule Views

#### Full Schedule Grid

```
GET /events/:eventId/schedule
```

Returns sessions × zones matrix with all assignments.

#### Schedule Summary

```
GET /events/:eventId/schedule/summary
```

Quick overview showing which sessions need coverage.

---

### Check-In System

Real-time attendance tracking for volunteer shifts.

#### Volunteer Self-Service

```
POST /auth/volunteer/check-in     # Check in to current assignment
POST /auth/volunteer/check-out    # Check out from current assignment
GET  /auth/volunteer/my-status    # Current status and upcoming shifts
```

#### Admin Check-In Management

```
POST   /events/:eventId/check-ins/:assignmentId  # Manual check-in
PUT    /events/:eventId/check-ins/:assignmentId  # Update (mark late, missed, etc.)
DELETE /events/:eventId/check-ins/:assignmentId  # Remove check-in record
```

**Admin Update Request:**

```json
{
  "status": "CHECKED_OUT",
  "isLate": true,
  "notes": "Arrived 15 minutes late due to traffic"
}
```

| Status        | Description       |
| ------------- | ----------------- |
| `CHECKED_IN`  | Currently on duty |
| `CHECKED_OUT` | Completed shift   |
| `MISSED`      | Did not show up   |

#### Status Views

```
GET /events/:eventId/check-ins/active                    # Currently checked-in volunteers
GET /events/:eventId/check-ins/by-zone/:zoneId          # Zone coverage status
GET /events/:eventId/check-ins/by-session/:sessionId    # Session attendance
GET /events/:eventId/check-ins/summary                  # Completion stats
GET /events/:eventId/check-ins/summary?sessionId=clx... # Filter by session
GET /events/:eventId/check-ins/summary?date=2026-03-22  # Filter by date
```

**Active Check-Ins Response:**

```json
{
  "activeCount": 8,
  "checkIns": [
    {
      "volunteer": { "name": "Manuel Smith", "...": "..." },
      "zone": { "name": "East Lobby", "...": "..." },
      "session": { "name": "Morning Session", "...": "..." },
      "checkInTime": "2026-03-22T09:18:00.000Z"
    }
  ]
}
```

**Zone Status Response:**

```json
{
  "zone": { "name": "East Lobby", "requiredCount": 2 },
  "activeCount": 2,
  "isFilled": true,
  "checkIns": ["..."]
}
```

**Summary Response:**

```json
{
  "summary": {
    "totalAssignments": 22,
    "checkedIn": 8,
    "checkedOut": 10,
    "missed": 1,
    "pending": 3,
    "lateArrivals": 2,
    "completionRate": 82
  },
  "byZone": [
    { "zone": "East Lobby", "required": 2, "active": 2, "isFilled": true }
  ],
  "lateArrivals": ["..."],
  "missedShifts": ["..."]
}
```

---

## Database Schema

```
admins
├── id, email, passwordHash, name, congregation

events
├── id, name, type, location, startDate, endDate, createdById

roles
├── id, name, displayOrder, eventId

volunteers
├── id, name, phone, email, congregation, appointment
├── generatedId, loginToken (auth credentials)
├── eventId, roleId

sessions
├── id, name, date, startTime, endTime, eventId

volunteer_availability
├── id, volunteerId, sessionId, isAvailable

zones
├── id, name, description, requiredCount, displayOrder, eventId

assignments
├── id, volunteerId, sessionId, zoneId, notes
├── UNIQUE(volunteerId, sessionId)

swap_requests
├── id, assignmentId, reason, status, suggestedVolunteerId
├── resolvedById, resolvedAt

check_ins
├── id, assignmentId, status, isLate
├── checkInTime, checkOutTime, notes
├── UNIQUE(assignmentId)
```

---

## Authentication

### Dual Auth System

| User Type | Credentials          | Scope            |
| --------- | -------------------- | ---------------- |
| Admin     | Email + password     | All their events |
| Volunteer | Generated ID + token | Single event     |

### JWT Payload

```json
{
  "id": "user-id",
  "type": "admin | volunteer",
  "email": "admin@example.com",
  "eventId": "event-id (volunteers only)"
}
```

### Protected Routes

Include token in Authorization header:

```
Authorization: Bearer <token>
```

---

## Docker

### Development

```bash
npm run docker:dev      # Start with hot reload
npm run docker:dev:down # Stop
```

### Production

```bash
npm run docker:build    # Build image (~150MB)
npm run docker:prod     # Start production
npm run docker:prod:down
```

### Pull from Registry

```bash
docker pull ghcr.io/jvil-dev/assembly-ops:latest
```

---

## Testing

```bash
npm test              # Run all tests
npm run test:watch    # Watch mode
npm run test:coverage # Coverage report
```

Tests include:

- **Unit tests:** Utility functions (credentials, passwords, tokens)
- **Integration tests:** API endpoints with database

---
