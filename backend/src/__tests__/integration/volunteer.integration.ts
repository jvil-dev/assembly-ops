/**
 * Volunteer Integration Tests
 *
 * Tests for volunteer-related GraphQL operations.
 * Volunteers are event participants who join via access code or by User ID.
 * Authenticated via generated volunteerId + token credentials (no password).
 *
 * Test Setup:
 *   1. Register a new overseer user
 *   2. Create a test event via Prisma
 *   3. Purchase a department to gain event access
 *
 * Tests:
 *   - createVolunteer: Legacy admin-only flow (still supported)
 *   - addVolunteerByUserId: Primary overseer flow — add existing user by short ID
 *   - loginEventVolunteer: Authenticate with volunteerId + token
 *   - volunteerToken: Query decrypted token (overseer-only, AES-256-GCM)
 *   - regenerateVolunteerCredentials: Generate new volunteerId + token
 *   - volunteers: Query event volunteers list
 *
 * Authorization:
 *   - Volunteer mutations require authenticated overseer with event access
 *   - volunteerToken requires overseer authentication
 */
import request from 'supertest';
import { createTestApp, closeTestApp } from '../setup.js';
import { createTestEvent } from '../testHelpers.js';
import type { Application } from 'express';

let app: Application;

describe('Volunteer Operations', () => {
  let accessToken: string;
  let eventId: string;
  let volunteerId: string; // Internal DB id (EventVolunteer)
  let volunteerCredentials: { volunteerId: string; token: string };
  let secondUserShortId: string; // 6-char userId of a second user for addVolunteerByUserId test

  beforeAll(async () => {
    app = await createTestApp();
    const email = `vol-test-${Date.now()}@example.com`;

    // Register overseer user
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
            firstName: 'Vol',
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
            purchaseDepartment(input: $input) {
              id
            }
          }
        `,
        variables: {
          input: {
            eventId,
            departmentType: 'INFORMATION_VOLUNTEER_SERVICE',
          },
        },
      });

    if (purchaseRes.body.errors) {
      console.error('Purchase failed:', purchaseRes.body.errors);
    }

    // Register a second user (volunteer) to test addVolunteerByUserId
    const secondEmail = `vol-test-second-${Date.now()}@example.com`;
    const secondRegisterRes = await request(app)
      .post('/graphql')
      .send({
        query: `
          mutation Register($input: RegisterUserInput!) {
            registerUser(input: $input) {
              user {
                userId
              }
            }
          }
        `,
        variables: {
          input: {
            email: secondEmail,
            password: 'TestPassword123!',
            firstName: 'Second',
            lastName: 'Volunteer',
            isOverseer: false,
          },
        },
      });

    if (!secondRegisterRes.body.errors) {
      secondUserShortId = secondRegisterRes.body.data.registerUser.user.userId;
    }
  });

  afterAll(async () => {
    await closeTestApp();
  });

  describe('createVolunteer', () => {
    it('should create a volunteer with credentials', async () => {
      if (!eventId) {
        console.log('Skipping - no event available');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation Create($eventId: ID!, $input: CreateVolunteerInput!) {
              createVolunteer(eventId: $eventId, input: $input) {
                id
                volunteerId
                token
                firstName
                lastName
              }
            }
          `,
          variables: {
            eventId,
            input: {
              firstName: 'Test',
              lastName: 'Volunteer',
              congregation: `Vol Cong ${Date.now()}`,
            },
          },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.createVolunteer.volunteerId).toMatch(/^[A-Z0-9]{6}$/);
      expect(response.body.data.createVolunteer.token).toBeDefined();

      volunteerId = response.body.data.createVolunteer.id;
      volunteerCredentials = {
        volunteerId: response.body.data.createVolunteer.volunteerId,
        token: response.body.data.createVolunteer.token,
      };
    });
  });

  describe('addVolunteerByUserId', () => {
    it('should add an existing user to the event by their short userId', async () => {
      if (!eventId || !secondUserShortId) {
        console.log('Skipping - no event or second user available');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation AddByUserId($eventId: ID!, $userId: String!) {
              addVolunteerByUserId(eventId: $eventId, userId: $userId) {
                volunteerId
                token
                inviteMessage
                eventVolunteer {
                  id
                  user {
                    firstName
                    lastName
                  }
                }
              }
            }
          `,
          variables: {
            eventId,
            userId: secondUserShortId,
          },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      const result = response.body.data.addVolunteerByUserId;
      expect(result.volunteerId).toMatch(/^[A-Z0-9]{6}$/);
      expect(result.token).toBeDefined();
      expect(result.inviteMessage).toBeDefined();
      expect(result.eventVolunteer.user.firstName).toBe('Second');
    });

    it('should reject adding the same user twice to the same event', async () => {
      if (!eventId || !secondUserShortId) {
        console.log('Skipping - no event or second user available');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation AddByUserId($eventId: ID!, $userId: String!) {
              addVolunteerByUserId(eventId: $eventId, userId: $userId) {
                volunteerId
              }
            }
          `,
          variables: {
            eventId,
            userId: secondUserShortId,
          },
        });

      expect(response.body.errors).toBeDefined();
    });
  });

  describe('loginEventVolunteer', () => {
    it('should login with valid credentials', async () => {
      if (!volunteerCredentials) {
        console.log('Skipping - no credentials available');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .send({
          query: `
            mutation Login($input: LoginEventVolunteerInput!) {
              loginEventVolunteer(input: $input) {
                eventVolunteer {
                  id
                }
                accessToken
                refreshToken
              }
            }
          `,
          variables: { input: volunteerCredentials },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.loginEventVolunteer.accessToken).toBeDefined();
    });
  });

  describe('volunteerToken', () => {
    it('should return decrypted token matching creation token', async () => {
      if (!volunteerId || !volunteerCredentials) {
        console.log('Skipping - no volunteer created');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            query VolunteerToken($id: ID!) {
              volunteerToken(id: $id)
            }
          `,
          variables: { id: volunteerId },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.volunteerToken).toBe(volunteerCredentials.token);
    });

    it('should reject unauthenticated requests', async () => {
      if (!volunteerId) {
        console.log('Skipping - no volunteer created');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .send({
          query: `
            query VolunteerToken($id: ID!) {
              volunteerToken(id: $id)
            }
          `,
          variables: { id: volunteerId },
        });

      expect(response.body.errors).toBeDefined();
    });
  });

  describe('regenerateVolunteerCredentials', () => {
    it('should regenerate and return new credentials', async () => {
      if (!volunteerId) {
        console.log('Skipping - no volunteer created');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation Regenerate($id: ID!) {
              regenerateVolunteerCredentials(id: $id) {
                volunteerId
                token
              }
            }
          `,
          variables: { id: volunteerId },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.regenerateVolunteerCredentials.volunteerId).toMatch(/^[A-Z0-9]{6}$/);
      expect(response.body.data.regenerateVolunteerCredentials.token).toBeDefined();
      expect(response.body.data.regenerateVolunteerCredentials.token).toHaveLength(8);

      // Verify the new token is retrievable via volunteerToken query
      const tokenResponse = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            query VolunteerToken($id: ID!) {
              volunteerToken(id: $id)
            }
          `,
          variables: { id: volunteerId },
        });

      expect(tokenResponse.body.errors).toBeUndefined();
      expect(tokenResponse.body.data.volunteerToken).toBe(
        response.body.data.regenerateVolunteerCredentials.token
      );
    });
  });

  describe('volunteers', () => {
    it('should return event volunteers', async () => {
      if (!eventId) {
        console.log('Skipping - no event available');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            query Volunteers($eventId: ID!) {
              volunteers(eventId: $eventId) {
                id
                volunteerId
                firstName
                lastName
                congregation
              }
            }
          `,
          variables: { eventId },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(Array.isArray(response.body.data.volunteers)).toBe(true);
    });
  });

  describe('join requests', () => {
    let requestUserToken: string;
    let joinRequestId: string;

    beforeAll(async () => {
      // Register a third user who will request to join
      const email = `join-req-${Date.now()}@example.com`;
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
              firstName: 'Join',
              lastName: 'Requester',
              isOverseer: false,
            },
          },
        });
      requestUserToken = registerRes.body.data.registerUser.accessToken;
    });

    it('should allow a user to request to join an event', async () => {
      if (!requestUserToken || !eventId) {
        console.log('Skipping - setup incomplete');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${requestUserToken}`)
        .send({
          query: `
            mutation Request($eventId: ID!) {
              requestToJoinEvent(eventId: $eventId) {
                id
                status
              }
            }
          `,
          variables: { eventId },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.requestToJoinEvent.status).toBe('PENDING');
      joinRequestId = response.body.data.requestToJoinEvent.id;
    });

    it('should allow the overseer to approve the join request', async () => {
      if (!joinRequestId) {
        console.log('Skipping - no join request created');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation Approve($requestId: ID!) {
              approveJoinRequest(requestId: $requestId) {
                volunteerId
                token
              }
            }
          `,
          variables: { requestId: joinRequestId },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.approveJoinRequest.volunteerId).toBeDefined();
      expect(response.body.data.approveJoinRequest.token).toBeDefined();
    });

    it('should allow the overseer to deny a join request', async () => {
      // Register a fresh user and submit a new request to deny
      const email = `deny-req-${Date.now()}@example.com`;
      const regRes = await request(app)
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
              firstName: 'Deny',
              lastName: 'Requester',
              isOverseer: false,
            },
          },
        });
      const denyUserToken = regRes.body.data.registerUser.accessToken;

      const reqRes = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${denyUserToken}`)
        .send({
          query: `
            mutation Request($eventId: ID!) {
              requestToJoinEvent(eventId: $eventId) {
                id
              }
            }
          `,
          variables: { eventId },
        });
      const denyRequestId = reqRes.body.data.requestToJoinEvent.id;

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation Deny($requestId: ID!, $reason: String) {
              denyJoinRequest(requestId: $requestId, reason: $reason) {
                id
                status
              }
            }
          `,
          variables: { requestId: denyRequestId, reason: 'No capacity' },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.denyJoinRequest.status).toBe('DENIED');
    });
  });
});
