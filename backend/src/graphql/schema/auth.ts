/**
 * GraphQL Auth Schema
 *
 * Defines authentication-related queries and mutations for admins (overseers).
 *
 * Types:
 *   - AuthPayload: Returned after login/register (admin + tokens)
 *   - TokenPayload: Returned after refresh (new tokens only)
 *   - LogoutPayload: Confirms logout success
 *
 * Queries:
 *   - me: Get the currently logged-in admin's profile
 *
 * Mutations:
 *   - registerAdmin: Create a new admin account
 *   - loginAdmin: Log in and get access + refresh tokens
 *   - refreshToken: Exchange refresh token for new access token
 *   - logoutAdmin: Invalidate a specific refresh token
 *   - logoutAllSessions: Invalidate ALL refresh tokens for this admin
 *
 * Flow:
 *   1. Admin registers or logs in → gets accessToken + refreshToken
 *   2. accessToken is sent in Authorization header for API calls
 *   3. When accessToken expires (15 min), use refreshToken to get a new one
 *   4. refreshToken expires after 7 days, then must log in again
 *
 * Implemented by: ../resolvers/auth.ts
 */
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
