/**
 * Audio/Video Department GraphQL Schema
 *
 * Type definitions for AV department features: equipment inventory,
 * checkout/return, damage reports, hazard assessments, and safety briefings.
 *
 * Enums:
 *   - AVEquipmentCategory: 16 equipment types (cameras, mixers, cables, etc.)
 *   - AVEquipmentCondition: GOOD, NEEDS_REPAIR, OUT_OF_SERVICE
 *   - AVDamageSeverity: MINOR, MODERATE, SEVERE
 *   - AVHazardType: 10 hazard categories (height, electrical, etc.)
 *
 * Types:
 *   - AVEquipmentItem: Equipment with category, condition, area, checkouts, damage
 *   - AVEquipmentCheckout: Chain-of-custody record (volunteer + session + timestamps)
 *   - AVDamageReport: Damage tracking with severity and resolution flow
 *   - AVHazardAssessment: Job hazard analysis with PPE requirements
 *   - AVSafetyBriefing: Pre-event safety briefing with attendees
 *   - AVSafetyBriefingAttendee: Join record linking volunteer to briefing
 *   - AVEquipmentSummary: Dashboard aggregate stats
 *   - AVCategorySummary: Per-category equipment counts
 *
 * Used by: ../resolvers/audioVideo.ts
 */
export const audioVideoTypeDefs = `#graphql
  enum AVEquipmentCategory {
    CAMERA_PTZ
    CAMERA_MANNED
    TRIPOD
    AUDIO_MIXER
    VIDEO_SWITCHER
    MEDIA_PLAYER
    LED_PANEL
    LOUDSPEAKER
    MICROPHONE
    STAGE_MONITOR
    INTERCOM
    CABLE
    STAGE_LIGHTING
    RECORDING_DEVICE
    ASSISTIVE_LISTENING
    ACCESSORY
  }

  enum AVEquipmentCondition {
    GOOD
    NEEDS_REPAIR
    OUT_OF_SERVICE
  }

  enum AVDamageSeverity {
    MINOR
    MODERATE
    SEVERE
  }

  enum AVHazardType {
    WORKING_AT_HEIGHT
    ELECTRICAL_EXPOSURE
    ELEVATED_PLATFORM
    POWER_TOOLS
    MOVING_EQUIPMENT
    NEAR_STAIRS
    UNEVEN_SURFACE
    HEAVY_LIFTING
    PINCH_CRUSH_CUT
    EXTREME_CONDITIONS
  }

  type AVEquipmentItem {
    id: ID!
    name: String!
    model: String
    serialNumber: String
    category: AVEquipmentCategory!
    condition: AVEquipmentCondition!
    location: String
    notes: String
    area: Area
    event: Event!
    currentCheckout: AVEquipmentCheckout
    checkoutHistory: [AVEquipmentCheckout!]!
    damageReports: [AVDamageReport!]!
    createdAt: String!
    updatedAt: String!
  }

  type AVEquipmentCheckout {
    id: ID!
    equipment: AVEquipmentItem!
    checkedOutBy: EventVolunteer!
    checkedOutAt: String!
    checkedInAt: String
    session: Session
    notes: String
  }

  type AVDamageReport {
    id: ID!
    equipment: AVEquipmentItem!
    description: String!
    severity: AVDamageSeverity!
    reportedBy: EventVolunteer!
    session: Session
    resolved: Boolean!
    resolvedAt: String
    resolvedBy: User
    resolutionNotes: String
    createdAt: String!
  }

  type AVHazardAssessment {
    id: ID!
    title: String!
    hazardType: AVHazardType!
    description: String!
    controls: String!
    ppeRequired: [String!]!
    completedBy: User!
    session: Session
    event: Event!
    completedAt: String!
  }

  type AVSafetyBriefing {
    id: ID!
    topic: String!
    notes: String
    conductedBy: User!
    conductedAt: String!
    event: Event!
    attendees: [AVSafetyBriefingAttendee!]!
    attendeeCount: Int!
  }

  type AVSafetyBriefingAttendee {
    id: ID!
    briefing: AVSafetyBriefing!
    eventVolunteer: EventVolunteer!
    createdAt: String!
  }

  type AVEquipmentSummary {
    totalItems: Int!
    checkedOutCount: Int!
    needsRepairCount: Int!
    outOfServiceCount: Int!
    byCategory: [AVCategorySummary!]!
  }

  type AVCategorySummary {
    category: AVEquipmentCategory!
    count: Int!
    checkedOutCount: Int!
  }

  input CreateAVEquipmentInput {
    eventId: ID!
    name: String!
    category: AVEquipmentCategory!
    condition: AVEquipmentCondition
    model: String
    serialNumber: String
    location: String
    notes: String
    areaId: ID
  }

  input BulkCreateAVEquipmentInput {
    eventId: ID!
    items: [AVEquipmentItemInput!]!
  }

  input AVEquipmentItemInput {
    name: String!
    category: AVEquipmentCategory!
    condition: AVEquipmentCondition
    model: String
    serialNumber: String
    location: String
    notes: String
    areaId: ID
  }

  input UpdateAVEquipmentInput {
    name: String
    category: AVEquipmentCategory
    condition: AVEquipmentCondition
    model: String
    serialNumber: String
    location: String
    notes: String
    areaId: ID
  }

  input CheckoutEquipmentInput {
    equipmentId: ID!
    checkedOutById: ID!
    sessionId: ID
    notes: String
  }

  input ReportAVDamageInput {
    equipmentId: ID!
    description: String!
    severity: AVDamageSeverity!
    sessionId: ID
  }

  input CreateAVHazardAssessmentInput {
    eventId: ID!
    title: String!
    hazardType: AVHazardType!
    description: String!
    controls: String!
    ppeRequired: [String!]!
    sessionId: ID
  }

  input CreateAVSafetyBriefingInput {
    eventId: ID!
    topic: String!
    notes: String
    attendeeIds: [ID!]!
  }

  extend type Query {
    avEquipment(eventId: ID!, category: AVEquipmentCategory, areaId: ID): [AVEquipmentItem!]!
    avEquipmentItem(id: ID!): AVEquipmentItem
    avEquipmentSummary(eventId: ID!): AVEquipmentSummary!
    avEquipmentCheckouts(eventId: ID!, checkedIn: Boolean): [AVEquipmentCheckout!]!
    avDamageReports(eventId: ID!, resolved: Boolean): [AVDamageReport!]!
    avHazardAssessments(eventId: ID!): [AVHazardAssessment!]!
    avSafetyBriefings(eventId: ID!): [AVSafetyBriefing!]!
    myAVSafetyBriefings(eventId: ID!): [AVSafetyBriefing!]!
  }

  extend type Mutation {
    createAVEquipment(input: CreateAVEquipmentInput!): AVEquipmentItem!
    bulkCreateAVEquipment(input: BulkCreateAVEquipmentInput!): [AVEquipmentItem!]!
    updateAVEquipment(id: ID!, input: UpdateAVEquipmentInput!): AVEquipmentItem!
    deleteAVEquipment(id: ID!): Boolean!
    checkoutEquipment(input: CheckoutEquipmentInput!): AVEquipmentCheckout!
    returnEquipment(checkoutId: ID!): AVEquipmentCheckout!
    reportAVDamage(input: ReportAVDamageInput!): AVDamageReport!
    resolveAVDamage(id: ID!, resolutionNotes: String): AVDamageReport!
    createAVHazardAssessment(input: CreateAVHazardAssessmentInput!): AVHazardAssessment!
    deleteAVHazardAssessment(id: ID!): Boolean!
    createAVSafetyBriefing(input: CreateAVSafetyBriefingInput!): AVSafetyBriefing!
    updateAVSafetyBriefingNotes(id: ID!, notes: String!): AVSafetyBriefing!
    deleteAVSafetyBriefing(id: ID!): Boolean!
  }
`;
