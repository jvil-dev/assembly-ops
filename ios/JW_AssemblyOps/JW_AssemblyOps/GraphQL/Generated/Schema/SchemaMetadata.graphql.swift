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
      case "CheckIn": return AssemblyOpsAPI.Objects.CheckIn
      case "Department": return AssemblyOpsAPI.Objects.Department
      case "Event": return AssemblyOpsAPI.Objects.Event
      case "EventTemplate": return AssemblyOpsAPI.Objects.EventTemplate
      case "MarkAllReadResult": return AssemblyOpsAPI.Objects.MarkAllReadResult
      case "Message": return AssemblyOpsAPI.Objects.Message
      case "Mutation": return AssemblyOpsAPI.Objects.Mutation
      case "Post": return AssemblyOpsAPI.Objects.Post
      case "Query": return AssemblyOpsAPI.Objects.Query
      case "ScheduleAssignment": return AssemblyOpsAPI.Objects.ScheduleAssignment
      case "Session": return AssemblyOpsAPI.Objects.Session
      case "TokenPayload": return AssemblyOpsAPI.Objects.TokenPayload
      case "Volunteer": return AssemblyOpsAPI.Objects.Volunteer
      case "VolunteerAuthPayload": return AssemblyOpsAPI.Objects.VolunteerAuthPayload
      default: return nil
      }
    }
  }

  enum Objects {}
  enum Interfaces {}
  enum Unions {}

}