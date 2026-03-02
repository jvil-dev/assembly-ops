/**
 * Area GraphQL Schema
 *
 * Type definitions for areas, area captains, and area groups.
 * Areas group posts within a department (Attendant dept initially).
 * Each area can have one captain per session.
 *
 * Types:
 *   - Area: A named grouping of posts within a department
 *   - AreaCaptainAssignment: Captain assigned to an area for a specific session
 *   - AreaGroup: Captain + all members (assignments) in an area for a session
 *   - AreaGroupMember: A single assignment within an area group, with post info
 *
 * Queries:
 *   - area(id): Get single area with posts and captains
 *   - departmentAreas(departmentId): Get all areas for a department
 *   - areaGroup(areaId, sessionId): Get area group (captain + members) for a session
 *   - myAreaGroups: Get all area groups where current volunteer is captain
 *
 * Mutations:
 *   - createArea: Create a new area in a department
 *   - updateArea: Update area name/description/sortOrder
 *   - deleteArea: Delete an area (posts remain, unlinked)
 *   - setAreaCaptain: Assign a captain to an area+session (upserts)
 *   - removeAreaCaptain: Remove captain from an area+session
 *   - assignPostToArea: Link a post to an area
 *   - removePostFromArea: Unlink a post from its area
 *
 * Used by: ./index.ts (schema composition)
 * Implemented by: ../resolvers/area.ts
 */
export const areaTypeDefs = `#graphql
  # ============================================
  # TYPES
  # ============================================

  type Area {
    id: ID!
    name: String!
    description: String
    category: String
    sortOrder: Int!
    department: Department!
    posts: [Post!]!
    captains: [AreaCaptainAssignment!]!
    postCount: Int!
    createdAt: DateTime!
    updatedAt: DateTime!
  }

  type AreaCaptainAssignment {
    id: ID!
    area: Area!
    session: Session!
    eventVolunteer: EventVolunteer!
    status: AssignmentStatus!
    respondedAt: DateTime
    declineReason: String
    acceptedDeadline: DateTime
    forceAssigned: Boolean!
    createdAt: DateTime!
  }

  type AreaGroup {
    area: Area!
    captain: AreaCaptainAssignment
    members: [AreaGroupMember!]!
  }

  type AreaGroupMember {
    assignment: ScheduleAssignment!
    postName: String!
    postId: ID!
  }

  # ============================================
  # INPUTS
  # ============================================

  input CreateAreaInput {
    name: String!
    description: String
    category: String
    sortOrder: Int
  }

  input UpdateAreaInput {
    name: String
    description: String
    category: String
    sortOrder: Int
  }

  input SetAreaCaptainInput {
    areaId: ID!
    sessionId: ID!
    eventVolunteerId: ID!
    forceAssigned: Boolean
    acceptedDeadline: DateTime
  }

  input AcceptAreaCaptainInput {
    areaCaptainId: ID!
  }

  input DeclineAreaCaptainInput {
    areaCaptainId: ID!
    reason: String
  }

  input RemoveAreaCaptainInput {
    areaId: ID!
    sessionId: ID!
  }

  # ============================================
  # QUERIES & MUTATIONS
  # ============================================

  extend type Query {
    area(id: ID!): Area
    departmentAreas(departmentId: ID!): [Area!]!
    areaGroup(areaId: ID!, sessionId: ID!): AreaGroup
    myAreaGroups: [AreaGroup!]!
    myCaptainAssignments(eventId: ID!): [AreaCaptainAssignment!]!
  }

  extend type Mutation {
    createArea(departmentId: ID!, input: CreateAreaInput!): Area!
    updateArea(id: ID!, input: UpdateAreaInput!): Area!
    deleteArea(id: ID!): Boolean!
    setAreaCaptain(input: SetAreaCaptainInput!): AreaCaptainAssignment!
    removeAreaCaptain(input: RemoveAreaCaptainInput!): Boolean!
    assignPostToArea(postId: ID!, areaId: ID!): Post!
    removePostFromArea(postId: ID!): Post!
    acceptAreaCaptain(input: AcceptAreaCaptainInput!): AreaCaptainAssignment!
    declineAreaCaptain(input: DeclineAreaCaptainInput!): AreaCaptainAssignment!
  }
`;
