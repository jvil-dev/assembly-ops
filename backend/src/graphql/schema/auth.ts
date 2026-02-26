/**
 * GraphQL Auth Schema
 *
 * Unified auth for all users (overseers and volunteers).
 * All users register/login through the same flow.
 * isOverseer flag controls access to overseer features.
 *
 * Implemented by: ../resolvers/auth.ts
 */
const authTypeDefs = `#graphql
  type UserAuthPayload {
    user: User!
    accessToken: String!
    refreshToken: String!
    expiresIn: Int!
  }

  type TokenPayload {
    accessToken: String!
    refreshToken: String!
    expiresIn: Int!
  }

  type LogoutPayload {
    success: Boolean!
  }

  type EventVolunteerAuthPayload {
    eventVolunteer: EventVolunteer!
    accessToken: String!
    refreshToken: String!
    expiresIn: Int!
  }

  input LoginEventVolunteerInput {
    volunteerId: String!
    token: String!
  }

  input RegisterUserInput {
    email: String!
    password: String!
    firstName: String!
    lastName: String!
    phone: String
    congregation: String
    congregationId: ID
    appointmentStatus: AppointmentStatus
    isOverseer: Boolean
  }

  input LoginUserInput {
    email: String!
    password: String!
  }

  input RefreshTokenInput {
    refreshToken: String!
  }

  input UpdateUserProfileInput {
    firstName: String
    lastName: String
    phone: String
    congregation: String
    congregationId: ID
  }

  extend type Query {
    me: User
  }

  extend type Mutation {
    registerUser(input: RegisterUserInput!): UserAuthPayload!
    loginUser(input: LoginUserInput!): UserAuthPayload!
    loginEventVolunteer(input: LoginEventVolunteerInput!): EventVolunteerAuthPayload!
    refreshToken(input: RefreshTokenInput!): TokenPayload!
    logoutUser(refreshToken: String!): LogoutPayload!
    logoutAllSessions: LogoutPayload!
    updateUserProfile(input: UpdateUserProfileInput!): User!
    setOverseerMode(isOverseer: Boolean!): User!
  }
`;

export default authTypeDefs;
