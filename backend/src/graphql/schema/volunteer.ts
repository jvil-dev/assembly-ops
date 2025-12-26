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
