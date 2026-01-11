/**
 * Message Integration Tests
 *
 * Tests for messaging operations between overseers and volunteers.
 *
 * Test suites:
 *   - sendMessage: Send message to individual volunteer
 *   - sendDepartmentMessage: Broadcast to department volunteers
 *   - sendBroadcast: Broadcast to all event volunteers
 *   - myMessages: Volunteer retrieves their messages
 *   - unreadMessageCount: Volunteer gets unread count
 *   - markMessageRead: Volunteer marks message as read
 */
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { createTestApp, closeTestApp } from '../setup.js';
import type { Application } from 'express';

describe('Message Operations', () => {
  let app: Application;
  let adminToken: string;
  let volunteerToken: string;
  let eventId: string;
  let departmentId: string;
  let volunteerId: string;
  let messageId: string;

  beforeAll(async () => {
    app = await createTestApp();
    const email = `message-test-${Date.now()}@example.com`;

    // Register admin
    const registerRes = await request(app)
      .post('/graphql')
      .send({
        query: `
          mutation Register($input: RegisterAdminInput!) {
            registerAdmin(input: $input) { accessToken }
          }
        `,
        variables: {
          input: {
            email,
            password: 'TestPassword123',
            firstName: 'Message',
            lastName: 'Tester',
            congregation: 'Test Congregation',
          },
        },
      });

    // Validate admin registration response
    if (!registerRes.body?.data?.registerAdmin?.accessToken) {
      throw new Error(
        `Admin registration failed: ${JSON.stringify(registerRes.body.errors || registerRes.body)}`
      );
    }
    adminToken = registerRes.body.data.registerAdmin.accessToken;

    // Setup event, department, volunteer
    const templatesRes = await request(app)
      .post('/graphql')
      .send({ query: `query { eventTemplates(serviceYear: 2026) { id } }` });

    if (templatesRes.body.data?.eventTemplates?.length === 0) {
      console.log('No event templates available - skipping message tests');
      return;
    }

    const templateId = templatesRes.body.data.eventTemplates[0].id;

    // Activate event
    const activateRes = await request(app)
      .post('/graphql')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        query: `mutation($input: ActivateEventInput!) { activateEvent(input: $input) { id } }`,
        variables: { input: { templateId } },
      });

    // Validate event activation
    if (!activateRes.body?.data?.activateEvent?.id) {
      throw new Error(
        `Event activation failed: ${JSON.stringify(activateRes.body.errors || activateRes.body)}`
      );
    }
    eventId = activateRes.body.data.activateEvent.id;

    // Claim department
    const claimRes = await request(app)
      .post('/graphql')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        query: `mutation($input: ClaimDepartmentInput!) { claimDepartment(input: $input) { id } }`,
        variables: { input: { eventId, departmentType: 'ATTENDANT' } },
      });

    // Validate department claim
    if (!claimRes.body?.data?.claimDepartment?.id) {
      throw new Error(
        `Department claim failed: ${JSON.stringify(claimRes.body.errors || claimRes.body)}`
      );
    }
    departmentId = claimRes.body.data.claimDepartment.id;

    // Create volunteer
    const volunteerRes = await request(app)
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
          input: { firstName: 'Test', lastName: 'Volunteer', congregation: 'Test Cong' },
        },
      });

    // Validate volunteer creation
    if (!volunteerRes.body?.data?.createVolunteer?.id) {
      throw new Error(
        `Volunteer creation failed: ${JSON.stringify(volunteerRes.body.errors || volunteerRes.body)}`
      );
    }
    volunteerId = volunteerRes.body.data.createVolunteer.id;
    const volunteerLoginId = volunteerRes.body.data.createVolunteer.volunteerId;
    const volunteerLoginToken = volunteerRes.body.data.createVolunteer.token;

    if (!volunteerLoginId || !volunteerLoginToken) {
      throw new Error('Volunteer creation did not return volunteerId or token');
    }

    // Assign volunteer to department
    const assignRes = await request(app)
      .post('/graphql')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        query: `mutation($id: ID!, $input: UpdateVolunteerInput!) {
          updateVolunteer(id: $id, input: $input) { id department { id } }
        }`,
        variables: { id: volunteerId, input: { departmentId } },
      });

    // Validate assignment
    if (!assignRes.body?.data?.updateVolunteer?.id) {
      throw new Error(
        `Volunteer assignment failed: ${JSON.stringify(assignRes.body.errors || assignRes.body)}`
      );
    }

    // Login as volunteer
    const volunteerLoginRes = await request(app)
      .post('/graphql')
      .send({
        query: `mutation($input: LoginVolunteerInput!) { loginVolunteer(input: $input) { accessToken } }`,
        variables: { input: { volunteerId: volunteerLoginId, token: volunteerLoginToken } },
      });

    // Validate volunteer login
    if (!volunteerLoginRes.body?.data?.loginVolunteer?.accessToken) {
      throw new Error(
        `Volunteer login failed: ${JSON.stringify(volunteerLoginRes.body.errors || volunteerLoginRes.body)}`
      );
    }
    volunteerToken = volunteerLoginRes.body.data.loginVolunteer.accessToken;
  });

  afterAll(async () => {
    await closeTestApp();
  });

  describe('sendMessage', () => {
    it('should send message to volunteer', async () => {
      if (!volunteerId) return;

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          query: `
            mutation SendMessage($input: SendMessageInput!) {
              sendMessage(input: $input) {
                id
                subject
                body
                recipientType
                isRead
              }
            }
          `,
          variables: {
            input: {
              volunteerId,
              subject: 'Schedule Change',
              body: 'Your shift has been moved to 2pm.',
            },
          },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.sendMessage.subject).toBe('Schedule Change');
      expect(response.body.data.sendMessage.recipientType).toBe('VOLUNTEER');
      expect(response.body.data.sendMessage.isRead).toBe(false);

      messageId = response.body.data.sendMessage.id;
    });
  });

  describe('sendDepartmentMessage', () => {
    it('should send message to all department volunteers', async () => {
      if (!departmentId) return;

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          query: `
            mutation SendDeptMessage($input: SendDepartmentMessageInput!) {
              sendDepartmentMessage(input: $input) {
                id
                recipientType
              }
            }
          `,
          variables: {
            input: {
              departmentId,
              subject: 'Department Update',
              body: 'Meeting at 8am tomorrow.',
            },
          },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.sendDepartmentMessage.length).toBeGreaterThan(0);
      expect(response.body.data.sendDepartmentMessage[0].recipientType).toBe('DEPARTMENT');
    });
  });

  describe('sendBroadcast', () => {
    it('should send message to all event volunteers', async () => {
      if (!eventId) return;

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          query: `
            mutation SendBroadcast($input: SendBroadcastInput!) {
              sendBroadcast(input: $input) {
                id
                recipientType
              }
            }
          `,
          variables: {
            input: {
              eventId,
              subject: 'Event Announcement',
              body: 'Welcome to the assembly!',
            },
          },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.sendBroadcast).toBeDefined();
      expect(response.body.data.sendBroadcast.length).toBeGreaterThan(0);
      expect(response.body.data.sendBroadcast[0].recipientType).toBe('EVENT');
    });
  });

  describe('myMessages (volunteer)', () => {
    it('should return volunteer messages', async () => {
      if (!volunteerToken) return;

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${volunteerToken}`)
        .send({
          query: `
            query {
              myMessages {
                id
                subject
                body
                isRead
              }
            }
          `,
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.myMessages.length).toBeGreaterThan(0);
    });
  });

  describe('unreadMessageCount', () => {
    it('should return unread count', async () => {
      if (!volunteerToken) return;

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${volunteerToken}`)
        .send({
          query: `query { unreadMessageCount }`,
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.unreadMessageCount).toBeGreaterThan(0);
    });
  });

  describe('markMessageRead', () => {
    it('should mark message as read', async () => {
      if (!volunteerToken || !messageId) return;

      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${volunteerToken}`)
        .send({
          query: `
            mutation MarkRead($id: ID!) {
              markMessageRead(id: $id) {
                id
                isRead
                readAt
              }
            }
          `,
          variables: { id: messageId },
        });

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.markMessageRead.isRead).toBe(true);
      expect(response.body.data.markMessageRead.readAt).not.toBeNull();
    });
  });
});
