/**
 * GraphQL Core Types
 *
 * Defines all data types that can be queried or returned by the API.
 * Admin model is replaced by User. VolunteerProfile is replaced by User.
 * All overseers and volunteers share the same User type.
 *
 * Used by: ./index.ts (combined into full schema)
 */
const types = `#graphql
  enum EventType {
    CIRCUIT_ASSEMBLY
    REGIONAL_CONVENTION
    SPECIAL_CONVENTION
  }

  enum EventRole {
    DEPARTMENT_OVERSEER
  }

  enum HierarchyRole {
    ASSISTANT_OVERSEER
  }

  enum DepartmentType {
    ACCOUNTS
    ATTENDANT
    AUDIO_VIDEO
    BAPTISM
    CLEANING
    FIRST_AID
    INFORMATION_VOLUNTEER_SERVICE
    INSTALLATION
    LOST_FOUND_CHECKROOM
    PARKING
    ROOMING
    TRUCKING_EQUIPMENT
  }

  enum AppointmentStatus {
    PUBLISHER
    MINISTERIAL_SERVANT
    ELDER
  }

  enum RecipientType {
    VOLUNTEER
    DEPARTMENT
    EVENT
    USER
  }

  enum MessageSenderType {
    USER
    VOLUNTEER
  }

  enum CheckInStatus {
    CHECKED_IN
    CHECKED_OUT
    NO_SHOW
  }

  enum JoinRequestStatus {
    PENDING
    APPROVED
    DENIED
  }

  type EventTemplate {
    id: ID!
    eventType: EventType!
    circuit: String
    region: String!
    serviceYear: Int!
    name: String!
    theme: String
    themeScripture: String
    venue: String!
    address: String!
    startDate: DateTime!
    endDate: DateTime!
    language: String!
    isActivated: Boolean!
    createdAt: DateTime!
  }

  type User {
    id: ID!
    userId: String!
    email: String!
    firstName: String!
    lastName: String!
    fullName: String!
    phone: String
    congregation: String
    congregationId: ID
    congregationRef: Congregation
    appointmentStatus: AppointmentStatus
    isOverseer: Boolean!
    eventRoles: [EventAdmin!]!
    createdAt: DateTime!
  }

  type Event {
    id: ID!
    template: EventTemplate!
    joinCode: String!
    isPublic: Boolean!
    admins: [EventAdmin!]!
    departments: [Department!]!
    sessions: [Session!]!
    roles: [Role!]!
    volunteerCount: Int!
    name: String!
    eventType: EventType!
    venue: String!
    address: String!
    startDate: DateTime!
    endDate: DateTime!
    createdAt: DateTime!
  }

  type EventAdmin {
    id: ID!
    user: User!
    event: Event!
    role: EventRole!
    department: Department
    claimedAt: DateTime!
  }

  type Department {
    id: ID!
    name: String!
    departmentType: DepartmentType!
    description: String
    accessCode: String
    isPublic: Boolean!
    event: Event!
    overseer: EventAdmin
    posts: [Post!]!
    volunteerCount: Int!
    isClaimed: Boolean!
    hierarchyRoles: [DepartmentHierarchy!]!
    createdAt: DateTime!
  }

  type DepartmentHierarchy {
    id: ID!
    department: Department!
    eventVolunteer: Volunteer!
    hierarchyRole: HierarchyRole!
    assignedAt: DateTime!
  }

  type Role {
    id: ID!
    name: String!
    description: String
    sortOrder: Int!
    event: Event!
    createdAt: DateTime!
  }

  type Volunteer {
    id: ID!
    volunteerId: String!
    firstName: String!
    lastName: String!
    fullName: String!
    email: String
    phone: String
    congregation: String!
    appointmentStatus: AppointmentStatus
    notes: String
    event: Event!
    department: Department
    role: Role
    assignments: [ScheduleAssignment!]!
    createdAt: DateTime!
  }

  type Post {
    id: ID!
    name: String!
    description: String
    location: String
    capacity: Int!
    category: String
    sortOrder: Int!
    department: Department!
    area: Area
    assignments: [ScheduleAssignment!]!
    assignmentCount: Int!
    createdAt: DateTime!
  }

  type Session {
    id: ID!
    name: String!
    date: DateTime!
    startTime: DateTime!
    endTime: DateTime!
    event: Event!
    assignments: [ScheduleAssignment!]!
    assignmentCount: Int!
    createdAt: DateTime!
  }

  type ScheduleAssignment {
    id: ID!
    eventVolunteer: EventVolunteer
    volunteer: Volunteer
    post: Post!
    session: Session!
    checkIn: CheckIn
    isCheckedIn: Boolean!
    isCaptain: Boolean!
    status: AssignmentStatus!
    respondedAt: DateTime
    declineReason: String
    acceptDeadline: DateTime
    forceAssigned: Boolean!
    createdAt: DateTime!
    updatedAt: DateTime!
  }

  enum AssignmentStatus {
    PENDING
    ACCEPTED
    DECLINED
    AUTO_DECLINED
  }

  type CheckIn {
    id: ID!
    status: CheckInStatus!
    checkInTime: DateTime!
    checkOutTime: DateTime
    notes: String
    assignment: ScheduleAssignment!
    checkedInBy: User
    createdAt: DateTime!
  }

  type Message {
    id: ID!
    subject: String
    body: String!
    recipientType: RecipientType!
    senderType: MessageSenderType
    senderName: String
    senderId: ID
    isRead: Boolean!
    readAt: DateTime
    event: Event!
    conversation: Conversation
    createdAt: DateTime!
  }

  type Conversation {
    id: ID!
    subject: String
    lastMessage: Message
    participants: [ConversationParticipant!]!
    unreadCount: Int!
    createdAt: DateTime!
    updatedAt: DateTime!
  }

  type ConversationParticipant {
    id: ID!
    participantType: MessageSenderType!
    participantId: ID!
    displayName: String!
    lastReadAt: DateTime
  }

  type AttendanceCount {
    id: ID!
    count: Int!
    section: String
    notes: String
    session: Session!
    post: Post
    createdAt: DateTime!
    updatedAt: DateTime!
    submittedBy: User!
  }

  type EventNote {
    id: ID!
    title: String
    body: String!
    department: Department!
    createdBy: User!
    createdAt: DateTime!
    updatedAt: DateTime!
  }

  type EventJoinRequest {
    id: ID!
    eventId: String!
    user: User!
    departmentType: DepartmentType
    status: JoinRequestStatus!
    note: String
    createdAt: DateTime!
    resolvedAt: DateTime
  }
`;

export default types;
