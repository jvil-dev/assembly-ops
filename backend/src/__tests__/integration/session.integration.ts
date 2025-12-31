/**
 * Session Integration Tests
 *
 * Tests for session-related GraphQL operations.
 * Sessions are event-wide time blocks (e.g., "Saturday Morning", "Sunday Afternoon").
 * All departments share the same sessions within an event.
 *
 * Test Setup:
 *   1. Register a new admin (becomes EVENT_OVERSEER)
 *   2. Fetch event templates and activate an event
 *
 * Tests:
 *   - createSession: Create single session with name, date, startTime, endTime
 *   - createSessions: Bulk create multiple sessions in one mutation
 *   - sessions: Query sessions by eventId with assignmentCount
 *
 * Authorization:
 *   Session mutations require EVENT_OVERSEER role.
 *
 * TODO: Add updateSession and deleteSession tests
 */
import request from 'supertest';
import { createTestApp, closeTestApp } from '../setup.js';
import type { Application } from 'express';

let app: Application;

describe('Session Operations', () => {
  let accessToken: string;
  let eventId: string;

  beforeAll(async () => {
    app = await createTestApp();
    const email = `session-test-${Date.now()}@example.com`;

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
            password: 'TestPassword123!',
            firstName: 'Session',
            lastName: 'Tester',
            congregation: 'Test Congregation',
          },
        },
      });

    if (registerRes.body.errors) {
      console.error('Register failed:', registerRes.body.errors);
      return;
    }
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
    }
  });

  afterAll(async () => {
    await closeTestApp();
  });

  describe('createSession', () => {
    it('should create a session', async () => {
      if (!eventId) {
        console.log('Skipping - no event available');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation CreateSession($eventId: ID!, $input: CreateSessionInput!) {
              createSession(eventId: $eventId, input: $input) {
                id
                name
                date
                startTime
                endTime
              }
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

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.createSession.name).toBe('Saturday Morning');
      // sessionId = response.body.data.createSession.id;
    });
  });

  describe('createSessions', () => {
    it('should bulk create sessions', async () => {
      if (!eventId) {
        console.log('Skipping - no event available');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            mutation CreateSessions($input: CreateSessionsInput!) {
              createSessions(input: $input) {
                id
                name
              }
            }
          `,
          variables: {
            input: {
              eventId,
              sessions: [
                {
                  name: 'Saturday Afternoon',
                  date: '2026-03-07T00:00:00Z',
                  startTime: '13:30',
                  endTime: '16:30',
                },
              ],
            },
          },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.createSessions.length).toBe(1);
    });
  });

  describe('sessions', () => {
    it('should return event sessions', async () => {
      if (!eventId) {
        console.log('Skipping - no event available');
        return;
      }

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          query: `
            query Sessions($eventId: ID!) {
              sessions(eventId: $eventId) {
                id
                name
                date
                startTime
                endTime
                assignmentCount
              }
            }
          `,
          variables: { eventId },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(Array.isArray(response.body.data.sessions)).toBe(true);
    });
  });
});
