// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class VolunteerAssignmentsQuery: GraphQLQuery {
    static let operationName: String = "VolunteerAssignments"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query VolunteerAssignments($volunteerId: ID!) { volunteerAssignments(volunteerId: $volunteerId) { __typename id isCaptain status forceAssigned post { __typename id name } session { __typename id name date } } }"#
      ))

    public var volunteerId: ID

    public init(volunteerId: ID) {
      self.volunteerId = volunteerId
    }

    public var __variables: Variables? { ["volunteerId": volunteerId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("volunteerAssignments", [VolunteerAssignment].self, arguments: ["volunteerId": .variable("volunteerId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        VolunteerAssignmentsQuery.Data.self
      ] }

      var volunteerAssignments: [VolunteerAssignment] { __data["volunteerAssignments"] }

      /// VolunteerAssignment
      ///
      /// Parent Type: `ScheduleAssignment`
      struct VolunteerAssignment: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.ScheduleAssignment }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("isCaptain", Bool.self),
          .field("status", GraphQLEnum<AssemblyOpsAPI.AssignmentStatus>.self),
          .field("forceAssigned", Bool.self),
          .field("post", Post.self),
          .field("session", Session.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          VolunteerAssignmentsQuery.Data.VolunteerAssignment.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var isCaptain: Bool { __data["isCaptain"] }
        var status: GraphQLEnum<AssemblyOpsAPI.AssignmentStatus> { __data["status"] }
        var forceAssigned: Bool { __data["forceAssigned"] }
        var post: Post { __data["post"] }
        var session: Session { __data["session"] }

        /// VolunteerAssignment.Post
        ///
        /// Parent Type: `Post`
        struct Post: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Post }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            VolunteerAssignmentsQuery.Data.VolunteerAssignment.Post.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// VolunteerAssignment.Session
        ///
        /// Parent Type: `Session`
        struct Session: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Session }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
            .field("date", AssemblyOpsAPI.DateTime.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            VolunteerAssignmentsQuery.Data.VolunteerAssignment.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var date: AssemblyOpsAPI.DateTime { __data["date"] }
        }
      }
    }
  }

}