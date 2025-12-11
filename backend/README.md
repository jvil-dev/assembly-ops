# AssemblyOps Backend

Node.js/Express API for the AssemblyOps volunteer management system.

## Tech Stack

- **Runtime:** Node.js 18+
- **Framework:** Express.js
- **Language:** TypeScript (ESM)
- **Database:** PostgreSQL (Supabase)
- **ORM:** Prisma 7
- **Auth:** JWT with bcrypt password hashing

## Setup

### Prerequisites

- Node.js 18+
- npm
- Supabase account (free tier)

### Installation

```bash
cd backend
npm install
```

### Environment Variables

Create a `.env` file:

```env
NODE_ENV=development
PORT=3000
DATABASE_URL="postgresql://postgres:PASSWORD@db.PROJECT.supabase.co:5432/postgres"
JWT_SECRET="your-secret-key"
JWT_EXPIRES_IN="7d"
```

### Database Setup

```bash
npx prisma generate
npx prisma migrate dev
```

### Run Development Server

```bash
npm run dev
```

Server runs at `http://localhost:3000`

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

Response:

```json
{
  "volunteer": {
    "id": "clx...",
    "name": "Manuel Smith",
    "generatedId": "VOL-A3B7K9",
    "role": { "id": "clx...", "name": "Attendant" }
  },
  "event": {
    "id": "clx...",
    "name": "Spring Circuit Assembly 2026",
    "type": "CIRCUIT_ASSEMBLY",
    "location": "Natick Assembly Hall"
  },
  "assignments": [
    {
      "id": "clx...",
      "session": { "name": "Morning Session", "...": "..." },
      "zone": { "name": "East Lobby", "...": "..." },
      "hasPendingSwapRequest": false
    }
  ],
  "totalAssignments": 2
}
```

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

Response:

```json
{
  "volunteerId": "clx...",
  "volunteerName": "Manuel Smith",
  "availability": [
    {
      "sessionId": "clx...",
      "sessionName": "Morning Session",
      "date": "2026-03-22T00:00:00.000Z",
      "startTime": "2026-03-22T09:20:00.000Z",
      "endTime": "2026-03-22T12:00:00.000Z",
      "isAvailable": true
    }
  ]
}
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

| Field         | Type   | Description                                  |
| ------------- | ------ | -------------------------------------------- |
| requiredCount | number | Volunteers needed (default: 1, min: 1)       |
| displayOrder  | number | Sort order (auto-increments if not provided) |

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

_Maximum 100 assignments per request. Validates all before creating any._

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

| Field                | Required | Description                    |
| -------------------- | -------- | ------------------------------ |
| assignmentId         | Yes      | The assignment to swap         |
| reason               | Yes      | Reason for the request         |
| suggestedVolunteerId | No       | Optional replacement volunteer |

**Validation:**

- Only one pending request per assignment
- Suggested volunteer must be available and not already assigned

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

_Approving deletes the original assignment. Admin must manually reassign if needed._

#### Deny Swap Request

```
PUT /events/:eventId/swap-requests/:requestId/deny
```

_Assignment remains unchanged._

---

### Schedule Views

Admin views for schedule overview.

#### Full Schedule Grid

```
GET /events/:eventId/schedule
```

Returns a sessions × zones matrix with all volunteer assignments:

```json
{
  "eventId": "clx...",
  "eventName": "Spring Circuit Assembly 2026",
  "sessions": [
    {
      "session": { "id": "clx...", "name": "Morning Session", "...": "..." },
      "zones": [
        {
          "zone": { "id": "clx...", "name": "East Lobby", "requiredCount": 2 },
          "assignedCount": 2,
          "isFilled": true,
          "volunteers": [
            {
              "id": "clx...",
              "name": "Manuel Smith",
              "assignmentId": "clx..."
            },
            { "id": "clx...", "name": "Saul Loyal", "assignmentId": "clx..." }
          ]
        }
      ],
      "totalRequired": 11,
      "totalAssigned": 8
    }
  ],
  "overallSummary": {
    "totalRequired": 22,
    "totalAssigned": 14,
    "fillPercentage": 64
  }
}
```

#### Schedule Summary

```
GET /events/:eventId/schedule/summary
```

Quick overview showing which sessions need coverage:

```json
{
  "sessions": [
    {
      "session": { "id": "clx...", "name": "Morning Session", "...": "..." },
      "totalRequired": 11,
      "totalAssigned": 8,
      "fillPercentage": 73,
      "isFilled": false,
      "zonesNeedingCoverage": [
        { "zoneName": "West Lobby", "required": 2, "assigned": 1, "needed": 1 },
        { "zoneName": "Auditorium", "required": 5, "assigned": 3, "needed": 2 }
      ]
    }
  ]
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

**Admin routes** - Include admin token:

```
Authorization: Bearer <admin-token>
```

**Volunteer routes** - Include volunteer token:

```
Authorization: Bearer <volunteer-token>
```

| Middleware         | Checks                             | Used For                         |
| ------------------ | ---------------------------------- | -------------------------------- |
| `requireAdmin`     | `type === "admin"`                 | All `/events/*` endpoints        |
| `requireVolunteer` | `type === "volunteer"` + `eventId` | `/auth/volunteer/my-assignments` |

---

## Scripts

| Script            | Command                   | Description                        |
| ----------------- | ------------------------- | ---------------------------------- |
| `dev`             | `npm run dev`             | Development server with hot reload |
| `build`           | `npm run build`           | Compile TypeScript                 |
| `start`           | `npm start`               | Run production server              |
| `prisma:generate` | `npm run prisma:generate` | Generate Prisma client             |
| `prisma:migrate`  | `npm run prisma:migrate`  | Run migrations                     |
| `prisma:studio`   | `npm run prisma:studio`   | Visual database browser            |

---

## Development Status

- [x] Phase 0: Project Setup
- [x] Phase 1: Authentication & Event Foundation
- [x] Phase 2: Volunteer Management & Sessions
- [x] Phase 3: Scheduling & Assignments
- [ ] Phase 4: Check-In/Check-Out
- [ ] Phase 5: Communication
- [ ] Phase 6: Offline Sync
- [ ] Phase 7: Reports & Polish
