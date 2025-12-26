/**
 * GraphQL Event Schema
 *
 * Defines event management queries and mutations.
 *
 * Queries:
 *   - eventTemplates: Get available event templates (from HQ, seeded data)
 *   - myEvents: Get all events the current admin has access to
 *   - event: Get a single event by ID
 *   - eventDepartments: Get all departments for an event
 *   - availableDepartments: Get department types not yet claimed
 *
 * Mutations:
 *   - activateEvent: Create a real event from a template
 *   - joinEvent: Join an existing event using a join code
 *   - claimDepartment: Claim a department as its overseer
 *
 * Event Lifecycle:
 *   1. Templates are seeded (Circuit Assembly 2025, etc.)
 *   2. Event Overseer activates a template → creates Event with joinCode
 *   3. Department Overseers join using the joinCode
 *   4. Department Overseers claim their department
 *   5. Overseers add volunteers, posts, sessions, assignments
 *
 * Implemented by: ../resolvers/event.ts
 */
const eventTypeDefs = `#graphql
  # ============================================
  # INPUTS
  # ============================================

  input ActivateEventInput {
    templateId: ID!
  }

  input JoinEventInput {
    joinCode: String!
  }

  input ClaimDepartmentInput {
    eventId: ID!
    departmentType: DepartmentType!
  }

  # ============================================
  # QUERIES & MUTATIONS
  # ============================================

  extend type Query {
    eventTemplates(serviceYear: Int): [EventTemplate!]!
    myEvents: [EventAdmin!]!
    event(id: ID!): Event
    eventDepartments(eventId: ID!): [Department!]!
    availableDepartments(eventId: ID!): [DepartmentType!]!
  }

  extend type Mutation {
    activateEvent(input: ActivateEventInput!): Event!
    joinEvent(input: JoinEventInput!): EventAdmin!
    claimDepartment(input: ClaimDepartmentInput!): Department!
  }
`;

export default eventTypeDefs;
