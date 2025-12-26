/**
 * Post GraphQL Schema
 *
 * Type definitions for post operations.
 * Posts are physical locations/positions within a department
 * (e.g., "Gate A", "Main Entrance", "Information Booth").
 *
 * Inputs:
 *   - CreatePostInput: name (required), description, location, capacity
 *   - CreatePostsInput: departmentId + array of posts (bulk creation)
 *   - UpdatePostInput: All fields optional (patch-style update)
 *
 * Queries:
 *   - post(id): Single post by ID
 *   - posts(departmentId): All posts in a department
 *   - eventPosts(eventId): All posts across an event
 *
 * Mutations: createPost, createPosts, updatePost, deletePost
 */
const postTypeDefs = `#graphql
  # ============================================
  # INPUTS
  # ============================================

  input CreatePostInput {
    name: String!
    description: String
    location: String
    capacity: Int
  }

  input CreatePostsInput {
    departmentId: ID!
    posts: [CreatePostInput!]!
  }

  input UpdatePostInput {
    name: String
    description: String
    location: String
    capacity: Int
  }

  # ============================================
  # QUERIES & MUTATIONS
  # ============================================

  extend type Query {
    post(id: ID!): Post
    posts(departmentId: ID!): [Post!]!
    eventPosts(eventId: ID!): [Post!]!
  }

  extend type Mutation {
    createPost(departmentId: ID!, input: CreatePostInput!): Post!
    createPosts(input: CreatePostsInput!): [Post!]!
    updatePost(id: ID!, input: UpdatePostInput!): Post!
    deletePost(id: ID!): Boolean!
  }
`;

export default postTypeDefs;
