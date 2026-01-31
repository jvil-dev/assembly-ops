export const circuitTypeDefs = `#graphql
    type Circuit {
        id: ID!
        code: String!
        region: String!
        language: String!
        congregations: [Congregation]!
        eventTemplates: [EventTemplate]!
        createdAt: DateTime!
        updatedAt: DateTime!    
    }

    extend type Query {
        circuits(region: String, language: String): [Circuit!]!
        circuit(id: ID!): Circuit
        circuitByCode(code: String!): Circuit
    }
`;
