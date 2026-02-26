export const congregationTypeDefs = `#graphql
    type Congregation {
        id: ID!
        name: String!
        city: String!
        state: String!
        language: String!
        circuit: Circuit!
        volunteerProfiles: [VolunteerProfile!]!
        createdAt: DateTime!
        updatedAt: DateTime!
    }

    extend type Query {
        congregations(state: String!, language: String): [Congregation!]!
        congregationsByCircuit(circuitId: ID!): [Congregation!]!
        congregation(id: ID!): Congregation
        searchCongregations(query: String!): [Congregation!]!
    }
`;
