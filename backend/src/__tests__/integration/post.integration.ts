/**
 * Post Integration Tests
 *
 * Tests for post-related GraphQL operations.
 * Posts are physical locations/positions within a department
 * (e.g., "Gate A", "Main Entrance", "Information Booth").
 *
 * Test Setup:
 *   1. Register a new admin
 *   2. Fetch event templates and activate an event
 *   3. Claim a department (ATTENDANT)
 *
 * Tests:
 *   - createPost: Create single post with name, description, location, capacity
 *   - createPosts: Bulk create multiple posts in one mutation
 *   - posts: Query posts by departmentId with assignmentCount
 *
 * TODO: Add updatePost and deletePost tests
 */
import request from 'supertest';
import app from '../../app.js';

describe('Post Operations', () => {
  let accessToken: string;
  let eventId: string;
  let departmentId: string;

  beforeAll(async () => {
    const email = `post-test-${Date.now()}@example.com`;

    // Register admin
    const registerRes = await request(app)
      .post('/graphql')
      .send({
        query: `
          mutation Register($input: RegisterAdminInput!) {
            registerAdmin(input: $input) {
              accessToken
            }
          }
        `,
        variables: {
          input: {
            email,
            password: 'TestPassword123',
            firstName: 'Post',
            lastName: 'Tester',
            congregation: 'Test Congregation',
          },
        },
      });

    accessToken = registerRes.body.data.registerAdmin.accessToken;

    // Get template and activate event
    const templatesRes = await request(app).post('/graphql').send({
      query: `query { eventTemplates(serviceYear: 2026) { id } }`,
    });

    if (templatesRes.body.data.eventTemplates.length > 0) {
      const templateId = templatesRes.body.data.eventTemplates[0].id;

      const activateRes = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation Activate($input: ActivateEventInput!) {
              activateEvent(input: $input) {
                id
              }
            }
          `,
          variables: { input: { templateId } },
        });

      eventId = activateRes.body.data.activateEvent.id;

      // Claim a department
      const claimRes = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation Claim($input: ClaimDepartmentInput!) {
              claimDepartment(input: $input) {
                id
              }
            }
          `,
          variables: {
            input: {
              eventId,
              departmentType: 'ATTENDANT',
            },
          },
        });

      departmentId = claimRes.body.data.claimDepartment.id;
    }
  });

  describe('createPost', () => {
    it('should create a post', async () => {
      if (!departmentId) {
        console.log('Skipping - no department available');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation CreatePost($departmentId: ID!, $input: CreatePostInput!) {
              createPost(departmentId: $departmentId, input: $input) {
                id
                name
                description
                location
                capacity
              }
            }
          `,
          variables: {
            departmentId,
            input: {
              name: 'East Lobby',
              description: 'Main entrance',
              location: 'Building A',
              capacity: 2,
            },
          },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.createPost.name).toBe('East Lobby');
      expect(response.body.data.createPost.capacity).toBe(2);
      // postId = response.body.data.createPost.id;
    });
  });

  describe('createPosts', () => {
    it('should bulk create posts', async () => {
      if (!departmentId) {
        console.log('Skipping - no department available');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation CreatePosts($input: CreatePostsInput!) {
              createPosts(input: $input) {
                id
                name
                capacity
              }
            }
          `,
          variables: {
            input: {
              departmentId,
              posts: [
                { name: 'West Lobby', capacity: 2 },
                { name: 'South Lobby', capacity: 1 },
                { name: 'Auditorium', capacity: 5 },
              ],
            },
          },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.createPosts.length).toBe(3);
    });
  });

  describe('posts', () => {
    it('should return department posts', async () => {
      if (!departmentId) {
        console.log('Skipping - no department available');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            query Posts($departmentId: ID!) {
              posts(departmentId: $departmentId) {
                id
                name
                capacity
                assignmentCount
              }
            }
          `,
          variables: { departmentId },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(Array.isArray(response.body.data.posts)).toBe(true);
      expect(response.body.data.posts.length).toBeGreaterThan(0);
    });
  });
});
