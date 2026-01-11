/**
 * Event Note Schema
 *
 * GraphQL type definitions for overseer coordination notes.
 *
 * Queries:
 *   - eventNote(id): Get note by ID
 *   - departmentNotes(departmentId): Get notes for a department
 *   - eventNotes(eventId): Get all notes for an event
 *
 * Mutations:
 *   - createEventNote: Create a new note
 *   - updateEventNote: Update an existing note
 *   - deleteEventNote: Delete a note
 */
const eventNoteTypeDefs = `#graphql
  # ============================================
  # INPUTS
  # ============================================

  input CreateEventNoteInput {
    departmentId: ID!
    title: String
    body: String!
  }

  input UpdateEventNoteInput {
    title: String
    body: String
  }

  # ============================================
  # QUERIES & MUTATIONS
  # ============================================

  extend type Query {
    eventNote(id: ID!): EventNote
    departmentNotes(departmentId: ID!): [EventNote!]!
    eventNotes(eventId: ID!): [EventNote!]!
  }

  extend type Mutation {
    createEventNote(input: CreateEventNoteInput!): EventNote!
    updateEventNote(id: ID!, input: UpdateEventNoteInput!): EventNote!
    deleteEventNote(id: ID!): Boolean!
  }
`;

export default eventNoteTypeDefs;
