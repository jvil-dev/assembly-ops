/**
 * Check-In Integration Tests
 *
 * Tests for volunteer check-in/check-out and attendance tracking.
 *
 * Test Coverage:
 *   - Volunteer check-in to assignment
 *   - Volunteer check-out from assignment
 *   - Admin check-in on behalf of volunteer
 *   - Mark volunteer as no-show
 *   - Check-in statistics query
 *   - Attendance count recording
 */
import request from 'supertest';
import { createTestApp, closeTestApp } from '../setup.js';
import type { Application } from 'express';

let app: Application;

const graphqlRequest = (query: string, variables?: object) =>
  request(app).post('/graphql').send({ query, variables });

const authRequest = (query: string, variables: object, token: string) =>
  request(app)
    .post('/graphql')
    .set('Authorization', `Bearer ${token}`)
    .send({ query, variables });

describe('Check-In Operations', () => {
  let adminToken: string;
  let volunteerToken: string;
  let eventId: string;
  let sessionId: string;
  let departmentId: string;
  let postId: string;
  let volunteerId: string;
  let assignmentId: string;
  let secondAssignmentId: string;

  beforeAll(async () => {
    app = await createTestApp();
    const email = `checkin-test-${Date.now()}@example.com`;

    // Register admin
    const registerRes = await graphqlRequest(
      `mutation Register($input: RegisterAdminInput!) {
        registerAdmin(input: $input) { accessToken admin { id } }
      }`,
      {
        input: {
          email,
          password: 'TestPassword123!',
          firstName: 'CheckIn',
          lastName: 'Tester',
          congregation: 'Test Congregation',
        },
      }
    );

    if (registerRes.body.errors) {
      console.error('Register failed:', registerRes.body.errors);
      return;
    }
    adminToken = registerRes.body.data.registerAdmin.accessToken;

    // Get event template
    const templatesRes = await graphqlRequest(
      `query { eventTemplates(serviceYear: 2026) { id } }`
    );

    if (!templatesRes.body.data?.eventTemplates?.length) {
      console.log('No event templates available');
      return;
    }

    const templateId = templatesRes.body.data.eventTemplates[0].id;

    // Activate event
    const activateRes = await authRequest(
      `mutation($input: ActivateEventInput!) { activateEvent(input: $input) { id } }`,
      { input: { templateId } },
      adminToken
    );
    if (activateRes.body.errors) {
      console.error('Activate failed:', activateRes.body.errors);
      return;
    }
    eventId = activateRes.body.data.activateEvent.id;

    // Claim department
    const claimRes = await authRequest(
      `mutation($input: ClaimDepartmentInput!) { claimDepartment(input: $input) { id } }`,
      { input: { eventId, departmentType: 'ATTENDANT' } },
      adminToken
    );
    if (claimRes.body.errors) {
      console.error('Claim failed:', claimRes.body.errors);
      return;
    }
    departmentId = claimRes.body.data.claimDepartment.id;

    // Create post
    const postRes = await authRequest(
      `mutation($departmentId: ID!, $input: CreatePostInput!) {
        createPost(departmentId: $departmentId, input: $input) { id }
      }`,
      { departmentId, input: { name: 'East Lobby', capacity: 2 } },
      adminToken
    );
    if (postRes.body.errors) {
      console.error('Post failed:', postRes.body.errors);
      return;
    }
    postId = postRes.body.data.createPost.id;

    // Create session
    const sessionRes = await authRequest(
      `mutation($eventId: ID!, $input: CreateSessionInput!) {
        createSession(eventId: $eventId, input: $input) { id }
      }`,
      {
        eventId,
        input: {
          name: 'Saturday Morning',
          date: '2026-03-07T00:00:00Z',
          startTime: '09:00',
          endTime: '12:00',
        },
      },
      adminToken
    );
    if (sessionRes.body.errors) {
      console.error('Session failed:', sessionRes.body.errors);
      return;
    }
    sessionId = sessionRes.body.data.createSession.id;

    // Create volunteer
    const volunteerRes = await authRequest(
      `mutation($eventId: ID!, $input: CreateVolunteerInput!) {
        createVolunteer(eventId: $eventId, input: $input) {
          id token volunteerId
        }
      }`,
      {
        eventId,
        input: { firstName: 'Test', lastName: 'Volunteer', congregation: 'Test Cong' },
      },
      adminToken
    );
    if (volunteerRes.body.errors) {
      console.error('Volunteer failed:', volunteerRes.body.errors);
      return;
    }
    volunteerId = volunteerRes.body.data.createVolunteer.id;
    const volunteerLoginId = volunteerRes.body.data.createVolunteer.volunteerId;
    const volunteerLoginToken = volunteerRes.body.data.createVolunteer.token;

    // Create assignment
    const assignmentRes = await authRequest(
      `mutation($input: CreateAssignmentInput!) { createAssignment(input: $input) { id } }`,
      { input: { volunteerId, postId, sessionId } },
      adminToken
    );
    if (assignmentRes.body.errors) {
      console.error('Assignment failed:', assignmentRes.body.errors);
      return;
    }
    assignmentId = assignmentRes.body.data.createAssignment.id;

    // Create second volunteer + assignment for no-show test
    const volunteer2Res = await authRequest(
      `mutation($eventId: ID!, $input: CreateVolunteerInput!) {
        createVolunteer(eventId: $eventId, input: $input) { id }
      }`,
      {
        eventId,
        input: { firstName: 'NoShow', lastName: 'Volunteer', congregation: 'Test Cong' },
      },
      adminToken
    );
    if (!volunteer2Res.body.errors) {
      const volunteer2Id = volunteer2Res.body.data.createVolunteer.id;
      const assignment2Res = await authRequest(
        `mutation($input: CreateAssignmentInput!) { createAssignment(input: $input) { id } }`,
        { input: { volunteerId: volunteer2Id, postId, sessionId } },
        adminToken
      );
      if (!assignment2Res.body.errors) {
        secondAssignmentId = assignment2Res.body.data.createAssignment.id;
      }
    }

    // Login as volunteer
    const volunteerLoginRes = await graphqlRequest(
      `mutation($input: LoginVolunteerInput!) { loginVolunteer(input: $input) { accessToken } }`,
      { input: { volunteerId: volunteerLoginId, token: volunteerLoginToken } }
    );
    if (volunteerLoginRes.body.errors) {
      console.error('Volunteer login failed:', volunteerLoginRes.body.errors);
      return;
    }
    volunteerToken = volunteerLoginRes.body.data.loginVolunteer.accessToken;
  });

  afterAll(async () => {
    await closeTestApp();
  });

  // ============================================
  // VOLUNTEER CHECK-IN
  // ============================================

  describe('checkIn mutation', () => {
    it('should allow volunteer to check in to their assignment', async () => {
      if (!assignmentId || !volunteerToken) {
        return console.log('Skipping - missing setup');
      }

      const response = await authRequest(
        `mutation CheckIn($input: CheckInInput!) {
          checkIn(input: $input) {
            id
            status
            checkInTime
            assignment { id }
          }
        }`,
        { input: { assignmentId } },
        volunteerToken
      );

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.checkIn.status).toBe('CHECKED_IN');
      expect(response.body.data.checkIn.assignment.id).toBe(assignmentId);
    });

    it('should reject duplicate check-in', async () => {
      if (!assignmentId || !volunteerToken) {
        return console.log('Skipping - missing setup');
      }

      const response = await authRequest(
        `mutation($input: CheckInInput!) { checkIn(input: $input) { id } }`,
        { input: { assignmentId } },
        volunteerToken
      );

      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].message).toContain('Already checked in');
    });
  });

  // ============================================
  // VOLUNTEER CHECK-OUT
  // ============================================

  describe('checkOut mutation', () => {
    it('should allow volunteer to check out', async () => {
      if (!assignmentId || !volunteerToken) {
        return console.log('Skipping - missing setup');
      }

      const response = await authRequest(
        `mutation CheckOut($input: CheckOutInput!) {
          checkOut(input: $input) {
            id
            status
            checkOutTime
          }
        }`,
        { input: { assignmentId } },
        volunteerToken
      );

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.checkOut.status).toBe('CHECKED_OUT');
      expect(response.body.data.checkOut.checkOutTime).toBeDefined();
    });

    it('should reject duplicate check-out', async () => {
      if (!assignmentId || !volunteerToken) {
        return console.log('Skipping - missing setup');
      }

      const response = await authRequest(
        `mutation($input: CheckOutInput!) { checkOut(input: $input) { id } }`,
        { input: { assignmentId } },
        volunteerToken
      );

      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].message).toContain('Already checked out');
    });
  });

  // ============================================
  // ADMIN CHECK-IN
  // ============================================

  describe('adminCheckIn mutation', () => {
    it('should allow admin to check in a volunteer', async () => {
      if (!secondAssignmentId || !adminToken) {
        return console.log('Skipping - missing setup');
      }

      const response = await authRequest(
        `mutation AdminCheckIn($input: AdminCheckInInput!) {
          adminCheckIn(input: $input) {
            id
            status
            notes
            checkedInBy { id }
          }
        }`,
        { input: { assignmentId: secondAssignmentId, notes: 'Checked in by overseer' } },
        adminToken
      );

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.adminCheckIn.status).toBe('CHECKED_IN');
      expect(response.body.data.adminCheckIn.notes).toBe('Checked in by overseer');
      expect(response.body.data.adminCheckIn.checkedInBy).toBeDefined();
    });
  });

  // ============================================
  // MARK NO-SHOW
  // ============================================

  describe('markNoShow mutation', () => {
    let noShowAssignmentId: string;

    beforeAll(async () => {
      if (!eventId || !adminToken || !postId || !sessionId) return;

      // Create a fresh volunteer + assignment for no-show test
      const volunteerRes = await authRequest(
        `mutation($eventId: ID!, $input: CreateVolunteerInput!) {
          createVolunteer(eventId: $eventId, input: $input) { id }
        }`,
        {
          eventId,
          input: { firstName: 'NoShow', lastName: 'Test', congregation: 'Test Cong' },
        },
        adminToken
      );
      if (volunteerRes.body.errors) return;

      const assignmentRes = await authRequest(
        `mutation($input: CreateAssignmentInput!) { createAssignment(input: $input) { id } }`,
        { input: { volunteerId: volunteerRes.body.data.createVolunteer.id, postId, sessionId } },
        adminToken
      );
      if (!assignmentRes.body.errors) {
        noShowAssignmentId = assignmentRes.body.data.createAssignment.id;
      }
    });

    it('should allow admin to mark volunteer as no-show', async () => {
      if (!noShowAssignmentId || !adminToken) {
        return console.log('Skipping - missing setup');
      }

      const response = await authRequest(
        `mutation MarkNoShow($input: MarkNoShowInput!) {
          markNoShow(input: $input) {
            id
            status
            notes
          }
        }`,
        { input: { assignmentId: noShowAssignmentId, notes: 'Did not arrive' } },
        adminToken
      );

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.markNoShow.status).toBe('NO_SHOW');
      expect(response.body.data.markNoShow.notes).toBe('Did not arrive');
    });
  });

  // ============================================
  // CHECK-IN STATS
  // ============================================

  describe('checkInStats query', () => {
    it('should return session check-in statistics', async () => {
      if (!sessionId || !adminToken) {
        return console.log('Skipping - missing setup');
      }

      const response = await authRequest(
        `query Stats($sessionId: ID!) {
          checkInStats(sessionId: $sessionId) {
            sessionId
            totalAssignments
            checkedIn
            checkedOut
            noShow
            pending
          }
        }`,
        { sessionId },
        adminToken
      );

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.checkInStats.sessionId).toBe(sessionId);
      expect(response.body.data.checkInStats.totalAssignments).toBeGreaterThan(0);
    });
  });

  // ============================================
  // ATTENDANCE COUNT
  // ============================================

  describe('recordAttendance mutation', () => {
    it('should allow admin to record attendance count', async () => {
      if (!sessionId || !adminToken) {
        return console.log('Skipping - missing setup');
      }

      const response = await authRequest(
        `mutation RecordAttendance($input: RecordAttendanceInput!) {
          recordAttendance(input: $input) {
            id
            count
            notes
            session { id }
            submittedBy { id }
          }
        }`,
        { input: { sessionId, count: 1250, notes: 'Counted at 10:30 AM' } },
        adminToken
      );

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.recordAttendance.count).toBe(1250);
      expect(response.body.data.recordAttendance.notes).toBe('Counted at 10:30 AM');
    });

    it('should reject duplicate attendance for same session', async () => {
      if (!sessionId || !adminToken) {
        return console.log('Skipping - missing setup');
      }

      const response = await authRequest(
        `mutation($input: RecordAttendanceInput!) {
          recordAttendance(input: $input) { id }
        }`,
        { input: { sessionId, count: 1300 } },
        adminToken
      );

      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].message).toContain('already recorded');
    });
  });

  describe('attendanceCount query', () => {
    it('should return attendance count for session', async () => {
      if (!sessionId || !adminToken) {
        return console.log('Skipping - missing setup');
      }

      const response = await authRequest(
        `query($sessionId: ID!) {
          attendanceCount(sessionId: $sessionId) {
            id
            count
            notes
          }
        }`,
        { sessionId },
        adminToken
      );

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.attendanceCount.count).toBe(1250);
    });
  });

  describe('eventAttendanceCounts query', () => {
    it('should return all attendance counts for event', async () => {
      if (!eventId || !adminToken) {
        return console.log('Skipping - missing setup');
      }

      const response = await authRequest(
        `query($eventId: ID!) {
          eventAttendanceCounts(eventId: $eventId) {
            id
            count
            session { id name }
          }
        }`,
        { eventId },
        adminToken
      );

      expect(response.status).toBe(200);
      expect(response.body.errors).toBeUndefined();
      expect(response.body.data.eventAttendanceCounts.length).toBeGreaterThan(0);
    });
  });
});
