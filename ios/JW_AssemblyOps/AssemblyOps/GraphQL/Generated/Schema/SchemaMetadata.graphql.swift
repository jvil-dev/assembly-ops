// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

protocol AssemblyOpsAPI_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == AssemblyOpsAPI.SchemaMetadata {}

protocol AssemblyOpsAPI_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == AssemblyOpsAPI.SchemaMetadata {}

protocol AssemblyOpsAPI_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == AssemblyOpsAPI.SchemaMetadata {}

protocol AssemblyOpsAPI_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == AssemblyOpsAPI.SchemaMetadata {}

extension AssemblyOpsAPI {
  typealias SelectionSet = AssemblyOpsAPI_SelectionSet

  typealias InlineFragment = AssemblyOpsAPI_InlineFragment

  typealias MutableSelectionSet = AssemblyOpsAPI_MutableSelectionSet

  typealias MutableInlineFragment = AssemblyOpsAPI_MutableInlineFragment

  enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      switch typename {
      case "AVCategorySummary": return AssemblyOpsAPI.Objects.AVCategorySummary
      case "AVDamageReport": return AssemblyOpsAPI.Objects.AVDamageReport
      case "AVEquipmentCheckout": return AssemblyOpsAPI.Objects.AVEquipmentCheckout
      case "AVEquipmentItem": return AssemblyOpsAPI.Objects.AVEquipmentItem
      case "AVEquipmentSummary": return AssemblyOpsAPI.Objects.AVEquipmentSummary
      case "AVHazardAssessment": return AssemblyOpsAPI.Objects.AVHazardAssessment
      case "AVSafetyBriefing": return AssemblyOpsAPI.Objects.AVSafetyBriefing
      case "AVSafetyBriefingAttendee": return AssemblyOpsAPI.Objects.AVSafetyBriefingAttendee
      case "Area": return AssemblyOpsAPI.Objects.Area
      case "AreaCaptainAssignment": return AssemblyOpsAPI.Objects.AreaCaptainAssignment
      case "AreaGroup": return AssemblyOpsAPI.Objects.AreaGroup
      case "AreaGroupMember": return AssemblyOpsAPI.Objects.AreaGroupMember
      case "AttendanceCount": return AssemblyOpsAPI.Objects.AttendanceCount
      case "AttendantMeeting": return AssemblyOpsAPI.Objects.AttendantMeeting
      case "CaptainAreaAttendanceCount": return AssemblyOpsAPI.Objects.CaptainAreaAttendanceCount
      case "CaptainGroup": return AssemblyOpsAPI.Objects.CaptainGroup
      case "CheckIn": return AssemblyOpsAPI.Objects.CheckIn
      case "CheckInStats": return AssemblyOpsAPI.Objects.CheckInStats
      case "Circuit": return AssemblyOpsAPI.Objects.Circuit
      case "Congregation": return AssemblyOpsAPI.Objects.Congregation
      case "Conversation": return AssemblyOpsAPI.Objects.Conversation
      case "ConversationParticipant": return AssemblyOpsAPI.Objects.ConversationParticipant
      case "CoverageAssignment": return AssemblyOpsAPI.Objects.CoverageAssignment
      case "CoverageCheckIn": return AssemblyOpsAPI.Objects.CoverageCheckIn
      case "CoveragePost": return AssemblyOpsAPI.Objects.CoveragePost
      case "CoverageSession": return AssemblyOpsAPI.Objects.CoverageSession
      case "CoverageShift": return AssemblyOpsAPI.Objects.CoverageShift
      case "CoverageSlot": return AssemblyOpsAPI.Objects.CoverageSlot
      case "CoverageVolunteer": return AssemblyOpsAPI.Objects.CoverageVolunteer
      case "CreatedVolunteer": return AssemblyOpsAPI.Objects.CreatedVolunteer
      case "Department": return AssemblyOpsAPI.Objects.Department
      case "DepartmentHierarchy": return AssemblyOpsAPI.Objects.DepartmentHierarchy
      case "Event": return AssemblyOpsAPI.Objects.Event
      case "EventAdmin": return AssemblyOpsAPI.Objects.EventAdmin
      case "EventJoinRequest": return AssemblyOpsAPI.Objects.EventJoinRequest
      case "EventParticipant": return AssemblyOpsAPI.Objects.EventParticipant
      case "EventVolunteer": return AssemblyOpsAPI.Objects.EventVolunteer
      case "FacilityLocation": return AssemblyOpsAPI.Objects.FacilityLocation
      case "LanyardCheckout": return AssemblyOpsAPI.Objects.LanyardCheckout
      case "LanyardSummary": return AssemblyOpsAPI.Objects.LanyardSummary
      case "LinkPlaceholderResult": return AssemblyOpsAPI.Objects.LinkPlaceholderResult
      case "LostPersonAlert": return AssemblyOpsAPI.Objects.LostPersonAlert
      case "MarkAllReadResult": return AssemblyOpsAPI.Objects.MarkAllReadResult
      case "MeetingAttendance": return AssemblyOpsAPI.Objects.MeetingAttendance
      case "Message": return AssemblyOpsAPI.Objects.Message
      case "Mutation": return AssemblyOpsAPI.Objects.Mutation
      case "MyAttendanceStatus": return AssemblyOpsAPI.Objects.MyAttendanceStatus
      case "OAuthAuthPayload": return AssemblyOpsAPI.Objects.OAuthAuthPayload
      case "Post": return AssemblyOpsAPI.Objects.Post
      case "PostSessionStatus": return AssemblyOpsAPI.Objects.PostSessionStatus
      case "Query": return AssemblyOpsAPI.Objects.Query
      case "ReminderConfirmation": return AssemblyOpsAPI.Objects.ReminderConfirmation
      case "ReminderVolunteerStatus": return AssemblyOpsAPI.Objects.ReminderVolunteerStatus
      case "Role": return AssemblyOpsAPI.Objects.Role
      case "SafetyIncident": return AssemblyOpsAPI.Objects.SafetyIncident
      case "ScheduleAssignment": return AssemblyOpsAPI.Objects.ScheduleAssignment
      case "Session": return AssemblyOpsAPI.Objects.Session
      case "SessionAttendanceSummary": return AssemblyOpsAPI.Objects.SessionAttendanceSummary
      case "Shift": return AssemblyOpsAPI.Objects.Shift
      case "ShiftReminderStatus": return AssemblyOpsAPI.Objects.ShiftReminderStatus
      case "TokenPayload": return AssemblyOpsAPI.Objects.TokenPayload
      case "User": return AssemblyOpsAPI.Objects.User
      case "UserAuthPayload": return AssemblyOpsAPI.Objects.UserAuthPayload
      case "UserEventMembership": return AssemblyOpsAPI.Objects.UserEventMembership
      case "Volunteer": return AssemblyOpsAPI.Objects.Volunteer
      case "VolunteerProfile": return AssemblyOpsAPI.Objects.VolunteerProfile
      case "WalkThroughCompletion": return AssemblyOpsAPI.Objects.WalkThroughCompletion
      default: return nil
      }
    }
  }

  enum Objects {}
  enum Interfaces {}
  enum Unions {}

}