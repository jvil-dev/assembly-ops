# AssemblyOps API Documentation

## Overview

AssemblyOps provides a GraphQL API for managing volunteer scheduling and assignments at religious assemblies and conventions. The API is built with Apollo Server and follows GraphQL best practices.

## Base URL

- **Development**: `http://localhost:4000/graphql`
- **Production**: `https://api.assemblyops.com/graphql` (TBD)

## Authentication

All API requests (except health check) require authentication using JWT tokens.

### Authentication Flow

1. **Register** or **Login** to obtain tokens
2. Include the access token in the `Authorization` header:
   ```
   Authorization: Bearer <access_token>
   ```
3. When the access token expires (15 minutes), use the refresh token to obtain a new one

### Endpoints

#### Register Admin (Overseer)

```graphql
mutation RegisterAdmin {
  registerAdmin(
    input: {
      email: "overseer@example.com"
      password: "SecurePassword123"
      firstName: "John"
      lastName: "Doe"
      congregation: "Central Congregation"
      isOverseer: true
    }
  ) {
    user {
      id
      email
      firstName
      lastName
    }
    accessToken
    refreshToken
    expiresIn
  }
}
```

#### Login

```graphql
mutation Login {
  loginUser(
    input: { email: "overseer@example.com", password: "SecurePassword123" }
  ) {
    user {
      id
      email
      firstName
      lastName
    }
    accessToken
    refreshToken
    expiresIn
  }
}
```

#### Refresh Token

```graphql
mutation RefreshToken {
  refreshToken(input: { refreshToken: "your_refresh_token_here" }) {
    accessToken
    refreshToken
    expiresIn
  }
}
```

## Authorization

The API uses role-based access control (RBAC):

| Role                    | Permissions                                                      |
| ----------------------- | ---------------------------------------------------------------- |
| **App Admin**           | Full platform administration, manage all events and users        |
| **Department Overseer** | Manage department posts, assign volunteers, view department data |
| **Volunteer**           | View own assignments, accept/decline assignments, check in/out   |

## Core Resources

### Events

Events represent assemblies or conventions that need volunteer staffing.

#### Get Available Event Templates

```graphql
query GetEventTemplates {
  eventTemplates(serviceYear: 2026) {
    id
    name
    eventType
    startDate
    endDate
    location
  }
}
```

#### Activate an Event

```graphql
mutation ActivateEvent {
  activateEvent(input: { templateId: "event_template_id" }) {
    id
    name
    joinCode
    startDate
    endDate
    departments {
      id
      name
      departmentType
    }
  }
}
```

#### Get Event Details

```graphql
query GetEvent($eventId: ID!) {
  event(id: $eventId) {
    id
    name
    startDate
    endDate
    location
    joinCode
    departments {
      id
      name
      departmentType
    }
    sessions {
      id
      name
      date
      startTime
      endTime
    }
  }
}
```

### Departments

Departments organize volunteers into functional groups (e.g., Attendant, Audio/Video, Parking).

#### Get Department Details

```graphql
query GetDepartment($departmentId: ID!) {
  department(id: $departmentId) {
    id
    name
    departmentType
    posts {
      id
      name
      capacity
      description
    }
    eventVolunteers {
      id
      user {
        firstName
        lastName
      }
    }
  }
}
```

### Posts

Posts are specific volunteer positions within a department (e.g., "East Lobby", "Main Entrance").

#### Create Posts

```graphql
mutation CreatePosts {
  createPosts(
    input: {
      departmentId: "dept_id"
      posts: [
        {
          name: "East Lobby"
          capacity: 2
          description: "Monitor east entrance"
        }
        {
          name: "West Lobby"
          capacity: 2
          description: "Monitor west entrance"
        }
      ]
    }
  ) {
    id
    name
    capacity
    description
  }
}
```

#### Update Post

```graphql
mutation UpdatePost {
  updatePost(
    input: { id: "post_id", name: "East Entrance (Updated)", capacity: 3 }
  ) {
    id
    name
    capacity
  }
}
```

### Sessions

Sessions are time blocks during the event (e.g., "Saturday Morning", "Sunday Afternoon").

#### Create Sessions

```graphql
mutation CreateSessions {
  createSessions(
    input: {
      eventId: "event_id"
      sessions: [
        {
          name: "Saturday Morning"
          date: "2026-03-07T00:00:00Z"
          startTime: "09:00"
          endTime: "12:00"
        }
        {
          name: "Saturday Afternoon"
          date: "2026-03-07T00:00:00Z"
          startTime: "13:30"
          endTime: "16:30"
        }
      ]
    }
  ) {
    id
    name
    date
    startTime
    endTime
  }
}
```

### Volunteers

Volunteers are users assigned to work at the event.

#### Create Volunteer

```graphql
mutation CreateVolunteer {
  createVolunteer(
    input: {
      eventId: "event_id"
      departmentId: "dept_id"
      firstName: "Jane"
      lastName: "Smith"
      email: "jane.smith@example.com"
      phone: "555-1234"
      congregation: "Westside Congregation"
    }
  ) {
    id
    userId
    firstName
    lastName
  }
}
```

#### Get Event Volunteers

```graphql
query GetEventVolunteers($eventId: ID!, $departmentId: ID) {
  eventVolunteers(eventId: $eventId, departmentId: $departmentId) {
    id
    firstName
    lastName
    email
    phone
    congregation
    assignments {
      id
      post {
        name
      }
      session {
        name
      }
      status
    }
  }
}
```

### Assignments

Assignments link volunteers to specific posts and sessions.

#### Create Assignment

```graphql
mutation CreateAssignment {
  createAssignment(
    input: {
      postId: "post_id"
      sessionId: "session_id"
      eventVolunteerId: "volunteer_id"
    }
  ) {
    id
    status
    post {
      name
    }
    session {
      name
      startTime
      endTime
    }
    eventVolunteer {
      firstName
      lastName
    }
  }
}
```

#### Accept Assignment

```graphql
mutation AcceptAssignment {
  acceptAssignment(assignmentId: "assignment_id") {
    id
    status
  }
}
```

#### Decline Assignment

```graphql
mutation DeclineAssignment {
  declineAssignment(assignmentId: "assignment_id") {
    id
    status
  }
}
```

### Check-In

Volunteers check in when they arrive at their assigned post.

#### Check In

```graphql
mutation CheckIn {
  checkIn(input: { assignmentId: "assignment_id" }) {
    id
    status
    checkedInAt
  }
}
```

#### Check Out

```graphql
mutation CheckOut {
  checkOut(input: { assignmentId: "assignment_id" }) {
    id
    status
    checkedOutAt
  }
}
```

## Error Handling

The API uses standard GraphQL error responses. All errors include:

- `message`: Human-readable error description
- `extensions.code`: Error code for programmatic handling

### Common Error Codes

| Code               | Description                               |
| ------------------ | ----------------------------------------- |
| `UNAUTHENTICATED`  | Missing or invalid authentication token   |
| `FORBIDDEN`        | Insufficient permissions                  |
| `NOT_FOUND`        | Resource not found                        |
| `VALIDATION_ERROR` | Invalid input data                        |
| `CONFLICT`         | Resource conflict (e.g., duplicate email) |

### Example Error Response

```json
{
  "errors": [
    {
      "message": "Not authenticated",
      "extensions": {
        "code": "UNAUTHENTICATED"
      }
    }
  ],
  "data": null
}
```

## Rate Limiting

To prevent abuse, the API implements rate limiting:

- **Authentication endpoints**: 20 requests per 15 minutes per IP
- **General endpoints**: 100 requests per minute per IP

When rate limit is exceeded, you'll receive:

```json
{
  "errors": [
    {
      "message": "Too many requests, please try again later"
    }
  ]
}
```

## GraphQL Introspection

The API supports GraphQL introspection. Use Apollo Studio Sandbox or any GraphQL client to explore the full schema:

**Development**: Navigate to `http://localhost:4000/graphql` in your browser

## Health Check

REST endpoint for monitoring:

```
GET /health
```

**Response** (200 OK):

```json
{
  "status": "healthy",
  "timestamp": "2026-03-01T12:00:00.000Z",
  "services": {
    "database": "connected"
  }
}
```

**Response** (503 Service Unavailable):

```json
{
  "status": "unhealthy",
  "timestamp": "2026-03-01T12:00:00.000Z",
  "services": {
    "database": "disconnected"
  }
}
```

## Best Practices

### Query Complexity

To prevent overly complex queries that could impact performance:

- Maximum query depth: 10 levels
- Pagination is enforced on list queries
- Use fragments to avoid duplicate fields

### Pagination

All list queries support pagination:

```graphql
query GetVolunteers {
  eventVolunteers(eventId: "event_id", first: 20, after: "cursor_value") {
    edges {
      node {
        id
        firstName
        lastName
      }
      cursor
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```

### Caching

- Use HTTP caching headers where appropriate
- Client-side caching recommended (Apollo Client, Relay)
- ETags supported for resource versioning

## SDK and Client Libraries

### Apollo Client (Recommended)

```typescript
import { ApolloClient, InMemoryCache, createHttpLink } from "@apollo/client";
import { setContext } from "@apollo/client/link/context";

const httpLink = createHttpLink({
  uri: "http://localhost:4000/graphql",
});

const authLink = setContext((_, { headers }) => {
  const token = localStorage.getItem("accessToken");
  return {
    headers: {
      ...headers,
      authorization: token ? `Bearer ${token}` : "",
    },
  };
});

const client = new ApolloClient({
  link: authLink.concat(httpLink),
  cache: new InMemoryCache(),
});
```

### iOS (Apollo iOS)

The iOS app uses Apollo iOS. See `ios/` directory for implementation examples.

## Support

For questions or issues:

1. Check this documentation
2. Review the [GraphQL schema](../backend/src/graphql/schema/)
3. Open an issue on GitHub
4. Contact the maintainers

## Versioning

The API follows semantic versioning. Breaking changes will be announced and deprecated endpoints will be supported for at least 6 months.

Current version: **v1.0.0**
