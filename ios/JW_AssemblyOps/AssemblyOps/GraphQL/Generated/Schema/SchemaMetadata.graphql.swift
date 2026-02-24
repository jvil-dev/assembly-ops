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
      case "Admin": return AssemblyOpsAPI.Objects.Admin
      case "Area": return AssemblyOpsAPI.Objects.Area
      case "AreaCaptainAssignment": return AssemblyOpsAPI.Objects.AreaCaptainAssignment
      case "AreaGroup": return AssemblyOpsAPI.Objects.AreaGroup
      case "AreaGroupMember": return AssemblyOpsAPI.Objects.AreaGroupMember
      case "AttendanceCount": return AssemblyOpsAPI.Objects.AttendanceCount
      case "AttendantMeeting": return AssemblyOpsAPI.Objects.AttendantMeeting
      case "AuthPayload": return AssemblyOpsAPI.Objects.AuthPayload
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
      case "CoverageSlot": return AssemblyOpsAPI.Objects.CoverageSlot
      case "CoverageVolunteer": return AssemblyOpsAPI.Objects.CoverageVolunteer
      case "CreatedVolunteer": return AssemblyOpsAPI.Objects.CreatedVolunteer
      case "Department": return AssemblyOpsAPI.Objects.Department
      case "Event": return AssemblyOpsAPI.Objects.Event
      case "EventAdmin": return AssemblyOpsAPI.Objects.EventAdmin
      case "EventParticipant": return AssemblyOpsAPI.Objects.EventParticipant
      case "EventTemplate": return AssemblyOpsAPI.Objects.EventTemplate
      case "EventVolunteer": return AssemblyOpsAPI.Objects.EventVolunteer
      case "EventVolunteerAuthPayload": return AssemblyOpsAPI.Objects.EventVolunteerAuthPayload
      case "EventVolunteerCredentials": return AssemblyOpsAPI.Objects.EventVolunteerCredentials
      case "FacilityLocation": return AssemblyOpsAPI.Objects.FacilityLocation
      case "LostPersonAlert": return AssemblyOpsAPI.Objects.LostPersonAlert
      case "MarkAllReadResult": return AssemblyOpsAPI.Objects.MarkAllReadResult
      case "MeetingAttendance": return AssemblyOpsAPI.Objects.MeetingAttendance
      case "Message": return AssemblyOpsAPI.Objects.Message
      case "Mutation": return AssemblyOpsAPI.Objects.Mutation
      case "OAuthAuthPayload": return AssemblyOpsAPI.Objects.OAuthAuthPayload
      case "Post": return AssemblyOpsAPI.Objects.Post
      case "PostSessionStatus": return AssemblyOpsAPI.Objects.PostSessionStatus
      case "Query": return AssemblyOpsAPI.Objects.Query
      case "Role": return AssemblyOpsAPI.Objects.Role
      case "SafetyIncident": return AssemblyOpsAPI.Objects.SafetyIncident
      case "ScheduleAssignment": return AssemblyOpsAPI.Objects.ScheduleAssignment
      case "Session": return AssemblyOpsAPI.Objects.Session
      case "SessionAttendanceSummary": return AssemblyOpsAPI.Objects.SessionAttendanceSummary
      case "TokenPayload": return AssemblyOpsAPI.Objects.TokenPayload
      case "Volunteer": return AssemblyOpsAPI.Objects.Volunteer
      case "VolunteerCredentials": return AssemblyOpsAPI.Objects.VolunteerCredentials
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