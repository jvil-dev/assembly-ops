const eventTypeDefs = `#graphql
  # ============================================
  # INPUTS
  # ============================================

  input ActivateEventInput {
    templateId: ID!
  }

  input JoinEventInput {
    joinCode: String!
  }

  input ClaimDepartmentInput {
    eventId: ID!
    departmentType: DepartmentType!
  }

  # ============================================
  # QUERIES & MUTATIONS
  # ============================================

  extend type Query {
    eventTemplates(serviceYear: Int): [EventTemplate!]!
    myEvents: [EventAdmin!]!
    event(id: ID!): Event
    eventDepartments(eventId: ID!): [Department!]!
    availableDepartments(eventId: ID!): [DepartmentType!]!
  }

  extend type Mutation {
    activateEvent(input: ActivateEventInput!): Event!
    joinEvent(input: JoinEventInput!): EventAdmin!
    claimDepartment(input: ClaimDepartmentInput!): Department!
  }
`;

export default eventTypeDefs;
