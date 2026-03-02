export const oauthTypeDefs = `#graphql
  enum AuthProvider {
    EMAIL
    GOOGLE
    APPLE
  }

  type OAuthAuthPayload {
    user: User
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
    isOverseer: Boolean
    congregation: String
    congregationId: ID
  }

  extend type Mutation {
    loginWithGoogle(input: GoogleAuthInput!): OAuthAuthPayload!
    loginWithApple(input: AppleAuthInput!): OAuthAuthPayload!
    completeOAuthRegistration(input: CompleteOAuthRegistrationInput!): UserAuthPayload!
  }
`;
