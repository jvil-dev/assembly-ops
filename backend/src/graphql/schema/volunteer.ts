/**
 * GraphQL Volunteer Schema
 *
 * Defines volunteer management queries and mutations.
 *
 * Types:
 *   - CreatedVolunteer: Returned when creating a volunteer (includes login credentials)
 *   - VolunteerAuthPayload: Returned when volunteer logs in
 *   - VolunteerCredentials: Just the volunteerId + token (for regeneration)
 *
 * Queries:
 *   - volunteer: Get a single volunteer by ID
 *   - volunteers: Get all volunteers for an event, optionally filtered by department
 *   - myVolunteerProfile: Get the logged-in volunteer's own profile
 *
 * Mutations:
 *   - createVolunteer: Add one volunteer to an event (returns login credentials)
 *   - createVolunteers: Bulk add multiple volunteers
 *   - updateVolunteer: Update volunteer details
 *   - deleteVolunteer: Remove a volunteer
 *   - regenerateVolunteerCredentials: Generate new login credentials
 *   - loginVolunteer: Volunteer logs in with volunteerId + token
 *
 * Volunteer Auth Flow:
 *   1. Overseer creates volunteer → gets volunteerId + token
 *   2. Volunteer receives credentials (printed card, SMS, etc.)
 *   3. Volunteer logs in with credentials → gets JWT
 *   4. Volunteer can view assignments and check in
 *
 * Implemented by: ../resolvers/volunteer.ts
 */
const volunteerTypeDefs = `#graphql
  # ============================================
  # TYPES
  # ============================================

  type CreatedVolunteer {
    id: ID!
    volunteerId: String!
    token: String!
    firstName: String!
    lastName: String!
    congregation: String!
  }

  type VolunteerAuthPayload {
    volunteer: Volunteer!
    accessToken: String!
    refreshToken: String!
    expiresIn: Int!
  }

  type VolunteerCredentials {
    volunteerId: String!
    token: String!
  }

  # ============================================
  # INPUTS
  # ============================================

  input CreateVolunteerInput {
    firstName: String!
    lastName: String!
    email: String
    phone: String
    congregation: String!
    appointmentStatus: AppointmentStatus
    notes: String
    departmentId: ID
    roleId: ID
  }

  input CreateVolunteersInput {
    eventId: ID!
    volunteers: [CreateVolunteerInput!]!
  }

  input UpdateVolunteerInput {
    firstName: String
    lastName: String
    email: String
    phone: String
    congregation: String
    appointmentStatus: AppointmentStatus
    notes: String
    departmentId: ID
    roleId: ID
  }

  input LoginVolunteerInput {
    volunteerId: String!
    token: String!
  }

  # ============================================
  # QUERIES & MUTATIONS
  # ============================================

  extend type Query {
    volunteer(id: ID!): Volunteer
    volunteers(eventId: ID!, departmentId: ID): [Volunteer!]!
    myVolunteerProfile: Volunteer
  }

  extend type Mutation {
    createVolunteer(eventId: ID!, input: CreateVolunteerInput!): CreatedVolunteer!
    createVolunteers(input: CreateVolunteersInput!): [CreatedVolunteer!]!
    updateVolunteer(id: ID!, input: UpdateVolunteerInput!): Volunteer!
    deleteVolunteer(id: ID!): Boolean!
    regenerateVolunteerCredentials(id: ID!): VolunteerCredentials!
    loginVolunteer(input: LoginVolunteerInput!): VolunteerAuthPayload!
  }
`;

export default volunteerTypeDefs;
