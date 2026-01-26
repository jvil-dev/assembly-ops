export const oauthTypeDefs = `#graphql
  enum AuthProvider {
    EMAIL
    GOOGLE
    APPLE
  }

  type OAuthAuthPayload {
    admin: Admin
    accessToken: String
    refreshToken: String
    expiresIn: Int
    isNewUser: Boolean!
    pendingOAuthToken: String
    email: String!
    firstName: String
    lastName: String
  }

  input GoogleAuthInput {
    idToken: String!
  }

  input AppleAuthInput {
    identityToken: String!
    firstName: String
    lastName: String
  }

  input CompleteOAuthRegistrationInput {
    pendingOAuthToken: String!
    firstName: String!
    lastName: String!
    phone: String
    congregation: String!
  }

  extend type Mutation {
    loginWithGoogle(input: GoogleAuthInput!): OAuthAuthPayload!
    loginWithApple(input: AppleAuthInput!): OAuthAuthPayload!
    completeOAuthRegistration(input: CompleteOAuthRegistrationInput!): AuthPayload!
  }
`;
