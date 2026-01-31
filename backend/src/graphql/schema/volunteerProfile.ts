export const volunteerProfileTypeDefs = `#graphql
  type VolunteerProfile {
    id: ID!
    firstName: String!
    lastName: String!
    email: String
    phone: String
    appointmentStatus: AppointmentStatus!
    notes: String
    congregation: Congregation!
    eventVolunteers: [EventVolunteer!]!
    createdAt: DateTime!
    updatedAt: DateTime!
  }

  type EventVolunteer {
    id: ID!
    volunteerId: String!
    token: String!
    volunteerProfile: VolunteerProfile!
    event: Event!
    department: Department
    role: Role
    assignments: [ScheduleAssignment!]!
    createdAt: DateTime!
    updatedAt: DateTime!
  }

  type EventVolunteerCredentials {
    eventVolunteer: EventVolunteer!
    volunteerId: String!
    token: String!
    inviteMessage: String!
  }

  input CreateVolunteerProfileInput {
    firstName: String!
    lastName: String!
    email: String
    phone: String
    appointmentStatus: AppointmentStatus
    notes: String
    congregationId: ID!
  }

  input UpdateVolunteerProfileInput {
    firstName: String
    lastName: String
    email: String
    phone: String
    appointmentStatus: AppointmentStatus
    notes: String
    congregationId: ID
  }

  input AddVolunteerToEventInput {
    volunteerProfileId: ID!
    eventId: ID!
    departmentId: ID
    roleId: ID
  }

  input CreateAndAddVolunteerInput {
    firstName: String!
    lastName: String!
    email: String
    phone: String
    appointmentStatus: AppointmentStatus
    notes: String
    congregationId: ID!
    eventId: ID!
    departmentId: ID
    roleId: ID
  }

  extend type Query {
    volunteerProfiles(congregationId: ID): [VolunteerProfile!]!
    volunteerProfilesByCircuit(circuitId: ID!): [VolunteerProfile!]!
    searchVolunteerProfiles(query: String!, circuitId: ID): [VolunteerProfile!]!
    volunteerProfile(id: ID!): VolunteerProfile
    eventVolunteer(id: ID!): EventVolunteer
    eventVolunteerByVolunteerId(volunteerId: String!): EventVolunteer
  }

  extend type Mutation {
    createVolunteerProfile(input: CreateVolunteerProfileInput!): VolunteerProfile!
    updateVolunteerProfile(id: ID!, input: UpdateVolunteerProfileInput!): VolunteerProfile!
    deleteVolunteerProfile(id: ID!): Boolean!

    addVolunteerToEvent(input: AddVolunteerToEventInput!): EventVolunteerCredentials!
    removeVolunteerFromEvent(eventVolunteerId: ID!): Boolean!

    createAndAddVolunteer(input: CreateAndAddVolunteerInput!): EventVolunteerCredentials!

    regenerateVolunteerToken(eventVolunteerId: ID!): EventVolunteerCredentials!
  }
`;
