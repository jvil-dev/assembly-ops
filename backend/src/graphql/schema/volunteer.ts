/**
 * GraphQL Volunteer Schema
 *
 * Volunteer management and join request operations.
 *
 * Implemented by: ../resolvers/volunteer.ts
 */
const volunteerTypeDefs = `#graphql
  # ============================================
  # TYPES
  # ============================================

  type CreatedVolunteer {
    id: ID!
    firstName: String!
    lastName: String!
    congregation: String!
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

  input UpdateMyProfileInput {
    phone: String
    email: String
  }

  # ============================================
  # QUERIES & MUTATIONS
  # ============================================

  extend type Query {
    volunteer(id: ID!): Volunteer
    volunteers(eventId: ID!, departmentId: ID): [Volunteer!]!
    myVolunteerProfile: Volunteer
    roles(eventId: ID!): [Role!]!
    # Join requests (user's own)
    myJoinRequests: [EventJoinRequest!]!
    # Join requests (overseer view)
    eventJoinRequests(eventId: ID!, status: JoinRequestStatus): [EventJoinRequest!]!
  }

  extend type Mutation {
    createVolunteer(eventId: ID!, input: CreateVolunteerInput!): CreatedVolunteer!
    createVolunteers(input: CreateVolunteersInput!): [CreatedVolunteer!]!
    updateVolunteer(id: ID!, input: UpdateVolunteerInput!): Volunteer!
    deleteVolunteer(id: ID!): Boolean!
    updateMyProfile(input: UpdateMyProfileInput!): Volunteer!
    # Join requests
    requestToJoinEvent(eventId: ID!, departmentType: DepartmentType, note: String): EventJoinRequest!
    cancelJoinRequest(requestId: ID!): Boolean!
    approveJoinRequest(requestId: ID!): EventVolunteer!
    denyJoinRequest(requestId: ID!, reason: String): EventJoinRequest!
  }
`;

export default volunteerTypeDefs;
