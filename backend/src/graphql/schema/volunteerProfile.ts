export const volunteerProfileTypeDefs = `#graphql
  type VolunteerProfile {
    id: ID!
    userId: String!
    firstName: String!
    lastName: String!
    email: String
    phone: String
    appointmentStatus: AppointmentStatus
    congregation: Congregation
    eventVolunteers: [EventVolunteer!]!
    createdAt: DateTime!
  }

  type EventVolunteer {
    id: ID!
    user: User!
    event: Event!
    department: Department
    role: Role
    assignments: [ScheduleAssignment!]!
    sessionAssignmentCount(sessionId: ID!): Int!
    createdAt: DateTime!
    updatedAt: DateTime!
  }

  input AddVolunteerToEventInput {
    userId: ID!
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
  }

  extend type Mutation {
    addVolunteerToEvent(input: AddVolunteerToEventInput!): EventVolunteer!
    removeVolunteerFromEvent(eventVolunteerId: ID!): Boolean!
    addVolunteerByUserId(eventId: ID!, userId: String!, departmentId: ID): EventVolunteer!
  }
`;
