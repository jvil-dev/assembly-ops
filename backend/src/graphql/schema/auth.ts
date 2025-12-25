const authTypeDefs = `#graphql
  type AuthPayload {
    admin: Admin!
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

  input RegisterAdminInput {
    email: String!
    password: String!
    firstName: String!
    lastName: String!
    phone: String
    congregation: String!
  }

  input LoginAdminInput {
    email: String!
    password: String!
  }

  input RefreshTokenInput {
    refreshToken: String!
  }

  extend type Query {
    me: Admin
  }

  extend type Mutation {
    registerAdmin(input: RegisterAdminInput!): AuthPayload!
    loginAdmin(input: LoginAdminInput!): AuthPayload!
    refreshToken(input: RefreshTokenInput!): TokenPayload!
    logoutAdmin(refreshToken: String!): LogoutPayload!
    logoutAllSessions: LogoutPayload!
  }
`;

export default authTypeDefs;
