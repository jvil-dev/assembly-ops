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
      case "AuthPayload": return AssemblyOpsAPI.Objects.AuthPayload
      case "CaptainGroup": return AssemblyOpsAPI.Objects.CaptainGroup
      case "CheckIn": return AssemblyOpsAPI.Objects.CheckIn
      case "Circuit": return AssemblyOpsAPI.Objects.Circuit
      case "Congregation": return AssemblyOpsAPI.Objects.Congregation
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
      case "EventTemplate": return AssemblyOpsAPI.Objects.EventTemplate
      case "EventVolunteer": return AssemblyOpsAPI.Objects.EventVolunteer
      case "EventVolunteerCredentials": return AssemblyOpsAPI.Objects.EventVolunteerCredentials
      case "MarkAllReadResult": return AssemblyOpsAPI.Objects.MarkAllReadResult
      case "Message": return AssemblyOpsAPI.Objects.Message
      case "Mutation": return AssemblyOpsAPI.Objects.Mutation
      case "OAuthAuthPayload": return AssemblyOpsAPI.Objects.OAuthAuthPayload
      case "Post": return AssemblyOpsAPI.Objects.Post
      case "Query": return AssemblyOpsAPI.Objects.Query
      case "Role": return AssemblyOpsAPI.Objects.Role
      case "ScheduleAssignment": return AssemblyOpsAPI.Objects.ScheduleAssignment
      case "Session": return AssemblyOpsAPI.Objects.Session
      case "TokenPayload": return AssemblyOpsAPI.Objects.TokenPayload
      case "Volunteer": return AssemblyOpsAPI.Objects.Volunteer
      case "VolunteerAuthPayload": return AssemblyOpsAPI.Objects.VolunteerAuthPayload
      case "VolunteerCredentials": return AssemblyOpsAPI.Objects.VolunteerCredentials
      case "VolunteerProfile": return AssemblyOpsAPI.Objects.VolunteerProfile
      default: return nil
      }
    }
  }

  enum Objects {}
  enum Interfaces {}
  enum Unions {}

}