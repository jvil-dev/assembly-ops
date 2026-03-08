export const floorPlanTypeDefs = `#graphql
  extend type Query {
    floorPlanUrl(eventId: ID!): String
  }

  extend type Mutation {
    getFloorPlanUploadUrl(eventId: ID!): String!
    confirmFloorPlanUpload(eventId: ID!): Boolean!
    deleteFloorPlan(eventId: ID!): Boolean!
  }
`;
