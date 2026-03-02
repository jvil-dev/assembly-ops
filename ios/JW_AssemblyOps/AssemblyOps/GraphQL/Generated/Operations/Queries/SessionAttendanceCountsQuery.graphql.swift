// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class SessionAttendanceCountsQuery: GraphQLQuery {
    static let operationName: String = "SessionAttendanceCounts"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SessionAttendanceCounts($sessionId: ID!) { sessionAttendanceCounts(sessionId: $sessionId) { __typename id count notes session { __typename id name } submittedBy { __typename id firstName lastName } createdAt } }"#
      ))

    public var sessionId: ID

    public init(sessionId: ID) {
      self.sessionId = sessionId
    }

    public var __variables: Variables? { ["sessionId": sessionId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("sessionAttendanceCounts", [SessionAttendanceCount].self, arguments: ["sessionId": .variable("sessionId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SessionAttendanceCountsQuery.Data.self
      ] }

      var sessionAttendanceCounts: [SessionAttendanceCount] { __data["sessionAttendanceCounts"] }

      /// SessionAttendanceCount
      ///
      /// Parent Type: `AttendanceCount`
      struct SessionAttendanceCount: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AttendanceCount }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("count", Int.self),
          .field("notes", String?.self),
          .field("session", Session.self),
          .field("submittedBy", SubmittedBy.self),
          .field("createdAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SessionAttendanceCountsQuery.Data.SessionAttendanceCount.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var count: Int { __data["count"] }
        var notes: String? { __data["notes"] }
        var session: Session { __data["session"] }
        var submittedBy: SubmittedBy { __data["submittedBy"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }

        /// SessionAttendanceCount.Session
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
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SessionAttendanceCountsQuery.Data.SessionAttendanceCount.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// SessionAttendanceCount.SubmittedBy
        ///
        /// Parent Type: `User`
        struct SubmittedBy: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.User }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("firstName", String.self),
            .field("lastName", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SessionAttendanceCountsQuery.Data.SessionAttendanceCount.SubmittedBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }
      }
    }
  }

}