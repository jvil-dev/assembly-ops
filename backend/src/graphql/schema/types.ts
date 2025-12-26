const types = `#graphql
  enum EventType {
    CIRCUIT_ASSEMBLY
    REGIONAL_CONVENTION
    SPECIAL_CONVENTION
  }

  enum EventRole {
    EVENT_OVERSEER
    DEPARTMENT_OVERSEER
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

  type Admin {
    id: ID!
    email: String!
    firstName: String!
    lastName: String!
    fullName: String!
    phone: String
    congregation: String
    eventRoles: [EventAdmin!]!
    createdAt: DateTime!
  }

  type Event {
    id: ID!
    template: EventTemplate!
    joinCode: String!
    admins: [EventAdmin!]!
    departments: [Department!]!
    sessions: [Session!]!
    roles: [Role!]!
    volunteers: [Volunteer!]!
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
    admin: Admin!
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
    event: Event!
    overseer: EventAdmin
    posts: [Post!]!
    volunteers: [Volunteer!]!
    volunteerCount: Int!
    isClaimed: Boolean!
    createdAt: DateTime!
  }

  type Role {
    id: ID!
    name: String!
    description: String
    sortOrder: Int!
    event: Event!
    volunteers: [Volunteer!]!
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
    department: Department!
    assignments: [ScheduleAssignment!]!
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
    createdAt: DateTime!
  }

  type ScheduleAssignment {
    id: ID!
    volunteer: Volunteer!
    post: Post!
    session: Session!
    checkIn: CheckIn
    isCheckedIn: Boolean!
    createdAt: DateTime!
  }

  type CheckIn {
    id: ID!
    checkInTime: DateTime!
    checkOutTime: DateTime
    assignment: ScheduleAssignment!
    session: Session!
    createdAt: DateTime!
  }

  type Message {
    id: ID!
    subject: String
    body: String!
    recipientType: RecipientType!
    isRead: Boolean!
    readAt: DateTime
    event: Event!
    sender: Admin
    createdAt: DateTime!
  }

  type AttendanceCount {
    id: ID!
    count: Int!
    notes: String
    session: Session!
    createdAt: DateTime!
  }

  type EventNote {
    id: ID!
    content: String!
    event: Event!
    department: Department
    createdAt: DateTime!
  }
`;

export default types;
