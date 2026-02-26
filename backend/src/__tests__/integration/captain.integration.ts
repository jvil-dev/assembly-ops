/**
 * Captain Role Integration Tests
 *
 * Tests for captain designation and group check-in capabilities.
 *
 * Test Coverage:
 *   - setCaptain: Admin designates assignment as captain
 *   - captainGroup: Returns volunteers at same post/session
 *   - captainCheckIn: Captain can check in group members
 *
 * Captain Role:
 *   Captains are group leaders who can check in volunteers without phones.
 *   A captain can only check in volunteers assigned to the same post/session.
 */
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { createTestApp, closeTestApp } from '../setup.js';
import type { Application } from 'express';

describe('Captain Operations', () => {
  let app: Application;
  let adminToken: string;
  let captainToken: string;
  // memberToken reserved for future test: verify members can't perform captain operations
  let eventId: string;
  let departmentId: string;
  let captainVolunteerId: string;
  let memberVolunteerId: string;
  let postId: string;
  let sessionId: string;
  let captainAssignmentId: string;
  let memberAssignmentId: string;

  beforeAll(async () => {
    app = await createTestApp();
    const email = `captain-test-${Date.now()}@example.com`;

    // Register user (overseer)
    const registerRes = await request(app)
      .post('/graphql')
      .send({
        query: `
          mutation Register($input: RegisterUserInput!) {
            registerUser(input: $input) { accessToken }
          }
        `,
        variables: {
          input: {
            email,
            password: 'TestPassword123',
            firstName: 'Captain',
            lastName: 'Tester',
            isOverseer: true,
          },
        },
      });

    adminToken = registerRes.body.data.registerUser.accessToken;

    // Setup event, department, post, session
    const templatesRes = await request(app)
      .post('/graphql')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ query: `query { eventTemplates(serviceYear: 2026) { id } }` });

    if (templatesRes.body.data.eventTemplates.length > 0) {
      const templateId = templatesRes.body.data.eventTemplates[0].id;

      const activateRes = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          query: `mutation($input: ActivateEventInput!) { activateEvent(input: $input) { id } }`,
          variables: { input: { templateId } },
        });
      eventId = activateRes.body.data.activateEvent.id;

      const claimRes = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          query: `mutation($input: ClaimDepartmentInput!) { claimDepartment(input: $input) { id } }`,
          variables: { input: { eventId, departmentType: 'ATTENDANT' } },
        });
      departmentId = claimRes.body.data.claimDepartment.id;

      const postRes = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          query: `mutation($departmentId: ID!, $input: CreatePostInput!) { createPost(departmentId: $departmentId, input: $input) { id } }`,
          variables: {
            departmentId,
            input: { name: 'Captain Post', capacity: 5 },
          },
        });
      postId = postRes.body.data.createPost.id;

      const sessionRes = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          query: `mutation($eventId: ID!, $input: CreateSessionInput!) { createSession(eventId: $eventId, input: $input) { id } }`,
          variables: {
            eventId,
            input: {
              name: 'Captain Session',
              date: '2026-03-18T00:00:00Z',
              startTime: '09:00',
              endTime: '12:00',
            },
          },
        });
      sessionId = sessionRes.body.data.createSession.id;

      // Create captain volunteer
      const captainRes = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          query: `mutation($eventId: ID!, $input: CreateVolunteerInput!) {
            createVolunteer(eventId: $eventId, input: $input) {
              id token volunteerId
            }
          }`,
          variables: {
            eventId,
            input: { firstName: 'Captain', lastName: 'Vol', congregation: 'Test Cong' },
          },
        });
      captainVolunteerId = captainRes.body.data.createVolunteer.id;
      const captainLoginId = captainRes.body.data.createVolunteer.volunteerId;
      const captainLoginToken = captainRes.body.data.createVolunteer.token;

      // Create member volunteer
      const memberRes = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          query: `mutation($eventId: ID!, $input: CreateVolunteerInput!) {
            createVolunteer(eventId: $eventId, input: $input) {
              id token volunteerId
            }
          }`,
          variables: {
            eventId,
            input: { firstName: 'Member', lastName: 'Vol', congregation: 'Test Cong' },
          },
        });
      memberVolunteerId = memberRes.body.data.createVolunteer.id;
      const memberLoginId = memberRes.body.data.createVolunteer.volunteerId;
      const memberLoginToken = memberRes.body.data.createVolunteer.token;

      // Assign both to department
      await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          query: `mutation($volunteerId: ID!, $departmentId: ID!) {
            assignVolunteerToDepartment(volunteerId: $volunteerId, departmentId: $departmentId) { id }
          }`,
          variables: { volunteerId: captainVolunteerId, departmentId },
        });

      await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          query: `mutation($volunteerId: ID!, $departmentId: ID!) {
            assignVolunteerToDepartment(volunteerId: $volunteerId, departmentId: $departmentId) { id }
          }`,
          variables: { volunteerId: memberVolunteerId, departmentId },
        });

      // Login both volunteers
      const captainLoginRes = await request(app)
        .post('/graphql')
        .send({
          query: `mutation($input: LoginEventVolunteerInput!) { loginEventVolunteer(input: $input) { accessToken } }`,
          variables: { input: { volunteerId: captainLoginId, token: captainLoginToken } },
        });
      captainToken = captainLoginRes.body.data.loginEventVolunteer.accessToken;

      // Member login reserved for future test: verify members can't perform captain operations
      await request(app)
        .post('/graphql')
        .send({
          query: `mutation($input: LoginEventVolunteerInput!) { loginEventVolunteer(input: $input) { accessToken } }`,
          variables: { input: { volunteerId: memberLoginId, token: memberLoginToken } },
        });

      // Create assignments (force-assign to skip acceptance flow for test setup)
      const captainAssignRes = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          query: `mutation($input: ForceAssignmentInput!) { forceAssignment(input: $input) { id } }`,
          variables: {
            input: { volunteerId: captainVolunteerId, postId, sessionId, isCaptain: true },
          },
        });
      captainAssignmentId = captainAssignRes.body.data.forceAssignment.id;

      const memberAssignRes = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          query: `mutation($input: ForceAssignmentInput!) { forceAssignment(input: $input) { id } }`,
          variables: {
            input: { volunteerId: memberVolunteerId, postId, sessionId },
          },
        });
      memberAssignmentId = memberAssignRes.body.data.forceAssignment.id;
    }
  });

  afterAll(async () => {
    await closeTestApp();
  });

  describe('setCaptain', () => {
    it('should set captain status on assignment', async () => {
      if (!captainAssignmentId) return;

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          query: `
            mutation SetCaptain($input: SetCaptainInput!) {
              setCaptain(input: $input) {
                id
                isCaptain
              }
            }
          `,
          variables: {
            input: { assignmentId: captainAssignmentId, isCaptain: true },
          },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.setCaptain.isCaptain).toBe(true);
    });
  });

  describe('captainGroup', () => {
    it('should return captain group members', async () => {
      if (!captainToken || !postId || !sessionId) return;

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${captainToken}`)
        .send({
          query: `
            query CaptainGroup($postId: ID!, $sessionId: ID!) {
              captainGroup(postId: $postId, sessionId: $sessionId) {
                captain { id isCaptain }
                members { id volunteer { firstName } checkIn { id } }
              }
            }
          `,
          variables: { postId, sessionId },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.captainGroup.captain.isCaptain).toBe(true);
      expect(response.body.data.captainGroup.members.length).toBeGreaterThan(0);
    });
  });

  describe('captainCheckIn', () => {
    it('should allow captain to check in a group member', async () => {
      if (!captainToken || !memberAssignmentId) return;

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${captainToken}`)
        .send({
          query: `
            mutation CaptainCheckIn($input: CaptainCheckInInput!) {
              captainCheckIn(input: $input) {
                id
                checkIn {
                  id
                  notes
                  status
                }
              }
            }
          `,
          variables: {
            input: { assignmentId: memberAssignmentId, notes: 'No phone' },
          },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.captainCheckIn.checkIn).not.toBeNull();
      expect(response.body.data.captainCheckIn.checkIn.notes).toContain('captain');
    });
  });
});
