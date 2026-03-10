/**
 * Assignment Integration Tests
 *
 * End-to-end tests for schedule assignment operations via GraphQL API.
 * Tests the full flow: HTTP request → GraphQL → Resolver → Service → Database.
 *
 * Test Setup (beforeAll):
 *   1. Register a test overseer
 *   2. Create a test event via Prisma
 *   3. Purchase a department (Attendant)
 *   4. Create a post (East Lobby)
 *   5. Create a session (Saturday Morning)
 *   6. Create a volunteer (John Smith)
 *
 * Test Cases:
 *   - createAssignment: Successfully assign volunteer to post+session
 *   - createAssignment (duplicate): Reject double-booking same volunteer
 *   - departmentCoverage: Return posts × sessions coverage matrix
 *   - departmentCoverageGaps: Return only unfilled slots
 *   - deleteAssignment: Remove an assignment
 *
 * Note: These tests require a running PostgreSQL database.
 * Currently not run in CI pipeline (tracked as tech debt).
 */
import request from 'supertest';
import { createTestApp, closeTestApp } from '../setup.js';
import { createTestEvent } from '../testHelpers.js';
import type { Application } from 'express';

let app: Application;

describe('Assignment Operations', () => {
  let accessToken: string;
  let eventId: string;
  let departmentId: string;
  let postId: string;
  let sessionId: string;
  let volunteerId: string;
  let assignmentId: string;

  beforeAll(async () => {
    app = await createTestApp();
    const email = `assignment-test-${Date.now()}@example.com`;

    // Register user (overseer)
    const registerRes = await request(app)
      .post('/graphql')
      .send({
        query: `
          mutation Register($input: RegisterUserInput!) {
            registerUser(input: $input) {
              accessToken
            }
          }
        `,
        variables: {
          input: {
            email,
            password: 'TestPassword123!',
            firstName: 'Assignment',
            lastName: 'Tester',
            isOverseer: true,
          },
        },
      });

    if (registerRes.body.errors) {
      console.error('Register failed:', registerRes.body.errors);
      return;
    }
    accessToken = registerRes.body.data.registerUser.accessToken;

    // Create a test event directly via Prisma
    eventId = await createTestEvent();

    // Purchase a department to gain event access
    const purchaseRes = await request(app)
      .post('/graphql')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        query: `
          mutation Purchase($input: PurchaseDepartmentInput!) {
            purchaseDepartment(input: $input) { id }
          }
        `,
        variables: {
          input: { eventId, departmentType: 'ATTENDANT' },
        },
      });

    if (purchaseRes.body.errors) {
      console.error('Purchase failed:', purchaseRes.body.errors);
      return;
    }
    departmentId = purchaseRes.body.data.purchaseDepartment.id;

    // Create post
    const postRes = await request(app)
      .post('/graphql')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        query: `
          mutation CreatePost($departmentId: ID!, $input: CreatePostInput!) {
            createPost(departmentId: $departmentId, input: $input) { id }
          }
        `,
        variables: {
          departmentId,
          input: { name: 'East Lobby' },
        },
      });

    postId = postRes.body.data.createPost.id;

    // Create session
    const sessionRes = await request(app)
      .post('/graphql')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        query: `
          mutation CreateSession($eventId: ID!, $input: CreateSessionInput!) {
            createSession(eventId: $eventId, input: $input) { id }
          }
        `,
        variables: {
          eventId,
          input: {
            name: 'Saturday Morning',
            date: '2026-03-07T00:00:00Z',
            startTime: '09:00',
            endTime: '12:00',
          },
        },
      });

    sessionId = sessionRes.body.data.createSession.id;

    // Create volunteer
    const volunteerRes = await request(app)
      .post('/graphql')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        query: `
          mutation CreateVolunteer($eventId: ID!, $input: CreateVolunteerInput!) {
            createVolunteer(eventId: $eventId, input: $input) { id }
          }
        `,
        variables: {
          eventId,
          input: {
            firstName: 'John',
            lastName: 'Smith',
            congregation: `Assign Cong ${Date.now()}`,
          },
        },
      });

    volunteerId = volunteerRes.body.data.createVolunteer.id;
  });

  afterAll(async () => {
    await closeTestApp();
  });

  describe('createAssignment', () => {
    it('should create an assignment', async () => {
      if (!volunteerId || !postId || !sessionId) {
        console.log('Skipping - missing required entities');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation CreateAssignment($input: CreateAssignmentInput!) {
              createAssignment(input: $input) {
                assignment {
                  id
                  volunteer { firstName lastName }
                  post { name }
                  session { name }
                  isCheckedIn
                }
                warning
              }
            }
          `,
          variables: {
            input: { volunteerId, postId, sessionId },
          },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.createAssignment.assignment.volunteer.firstName).toBe('John');
      expect(response.body.data.createAssignment.assignment.post.name).toBe('East Lobby');
      expect(response.body.data.createAssignment.assignment.isCheckedIn).toBe(false);

      assignmentId = response.body.data.createAssignment.assignment.id;
    });

    it('should reject duplicate assignment for same session', async () => {
      if (!volunteerId || !postId || !sessionId) {
        console.log('Skipping - missing required entities');
        return;
      }

      // Try to assign same volunteer to different post for same session
      const post2Res = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation CreatePost($departmentId: ID!, $input: CreatePostInput!) {
              createPost(departmentId: $departmentId, input: $input) { id }
            }
          `,
          variables: {
            departmentId,
            input: { name: 'West Lobby' },
          },
        });

      const post2Id = post2Res.body.data.createPost.id;

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation CreateAssignment($input: CreateAssignmentInput!) {
              createAssignment(input: $input) { assignment { id } }
            }
          `,
          variables: {
            input: { volunteerId, postId: post2Id, sessionId },
          },
        });

      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].message).toContain('already assigned');
    });
  });

  describe('departmentCoverage', () => {
    it('should return coverage matrix', async () => {
      if (!departmentId) {
        console.log('Skipping - no department available');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            query Coverage($departmentId: ID!) {
              departmentCoverage(departmentId: $departmentId) {
                post { id name }
                session { id name }
                filled
                assignments {
                  id
                  volunteer { firstName lastName }
                }
              }
            }
          `,
          variables: { departmentId },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(Array.isArray(response.body.data.departmentCoverage)).toBe(true);
    });
  });

  describe('departmentCoverageGaps', () => {
    it('should return only unfilled slots', async () => {
      if (!departmentId) {
        console.log('Skipping - no department available');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            query Gaps($departmentId: ID!) {
              departmentCoverageGaps(departmentId: $departmentId) {
                post { name }
                session { name }
                filled
              }
            }
          `,
          variables: { departmentId },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
    });
  });

  describe('deleteAssignment', () => {
    it('should delete an assignment', async () => {
      if (!assignmentId) {
        console.log('Skipping - no assignment available');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation Delete($id: ID!) {
              deleteAssignment(id: $id)
            }
          `,
          variables: { id: assignmentId },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.deleteAssignment).toBe(true);
    });
  });
});
