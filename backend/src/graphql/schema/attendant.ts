/**
 * Attendant GraphQL Schema
 *
 * Type definitions for attendant department operational features:
 * safety incidents, lost person alerts, and pre-event meetings.
 *
 * Enums:
 *   - SafetyIncidentType: 8 incident categories (building defect, wet floor, etc.)
 *
 * Types:
 *   - SafetyIncident: Incident report with resolution tracking
 *   - LostPersonAlert: Missing person report with contact info
 *   - AttendantMeeting: Pre-event briefing with attendee list
 *   - MeetingAttendance: Join record linking volunteer to meeting
 *
 * Queries:
 *   - safetyIncidents(eventId, resolved?): Filter incidents by event/status
 *   - lostPersonAlerts(eventId, resolved?): Filter alerts by event/status
 *   - attendantMeetings(eventId): All meetings for an event
 *   - myAttendantMeetings(eventId): Volunteer's assigned meetings
 *
 * Mutations:
 *   - reportSafetyIncident / resolveSafetyIncident
 *   - createLostPersonAlert / resolveLostPersonAlert
 *   - createAttendantMeeting / updateAttendantMeetingNotes / deleteAttendantMeeting
 *
 * Used by: ../resolvers/attendant.ts
 */
export const attendantTypeDefs = `#graphql
  enum SafetyIncidentType {
    BUILDING_DEFECT
    WET_FLOOR
    UNSAFE_CONDITION
    MEDICAL_EMERGENCY
    DISRUPTIVE_INDIVIDUAL
    BOMB_THREAT
    VIOLENT_INDIVIDUAL
    SEVERE_WEATHER
    ACTIVE_SHOOTER
    OTHER
  }

  type SafetyIncident {
    id: ID!
    type: SafetyIncidentType!
    description: String!
    location: String
    post: Post
    reportedBy: EventVolunteer!
    event: Event!
    resolved: Boolean!
    resolvedAt: String
    resolvedBy: Admin
    resolutionNotes: String
    createdAt: String!
  }

  type LostPersonAlert {
    id: ID!
    personName: String!
    age: Int
    description: String!
    lastSeenLocation: String
    lastSeenTime: String
    contactName: String!
    contactPhone: String
    reportedBy: EventVolunteer!
    event: Event!
    resolved: Boolean!
    resolvedAt: String
    resolvedBy: Admin
    resolutionNotes: String
    createdAt: String!
  }

  type AttendantMeeting {
    id: ID!
    session: Session!
    event: Event!
    meetingDate: String!
    notes: String
    createdBy: Admin!
    attendees: [MeetingAttendance!]!
    createdAt: String!
    updatedAt: String!
  }

  type MeetingAttendance {
    id: ID!
    meeting: AttendantMeeting!
    eventVolunteer: EventVolunteer!
    createdAt: String!
  }

  input ReportSafetyIncidentInput {
    eventId: ID!
    type: SafetyIncidentType!
    description: String!
    location: String
    postId: ID
    sessionId: ID
  }

  input CreateLostPersonAlertInput {
    eventId: ID!
    personName: String!
    age: Int
    description: String!
    lastSeenLocation: String
    lastSeenTime: String
    contactName: String!
    contactPhone: String
    sessionId: ID
  }

  input CreateAttendantMeetingInput {
    eventId: ID!
    sessionId: ID!
    meetingDate: String!
    notes: String
    attendeeIds: [ID!]!
  }

  extend type Query {
    safetyIncidents(eventId: ID!, resolved: Boolean): [SafetyIncident!]!
    lostPersonAlerts(eventId: ID!, resolved: Boolean): [LostPersonAlert!]!
    attendantMeetings(eventId: ID!): [AttendantMeeting!]!
    myAttendantMeetings(eventId: ID!): [AttendantMeeting!]!
  }

  extend type Mutation {
    reportSafetyIncident(input: ReportSafetyIncidentInput!): SafetyIncident!
    resolveSafetyIncident(id: ID!, resolutionNotes: String): SafetyIncident!
    createLostPersonAlert(input: CreateLostPersonAlertInput!): LostPersonAlert!
    resolveLostPersonAlert(id: ID!, resolutionNotes: String!): LostPersonAlert!
    createAttendantMeeting(input: CreateAttendantMeetingInput!): AttendantMeeting!
    updateAttendantMeetingNotes(id: ID!, notes: String!): AttendantMeeting!
    deleteAttendantMeeting(id: ID!): Boolean!
  }
`;
