// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class PostAttendanceCountsQuery: GraphQLQuery {
    static let operationName: String = "PostAttendanceCounts"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query PostAttendanceCounts($postId: ID!) { postAttendanceCounts(postId: $postId) { __typename id count section notes session { __typename id name } createdAt updatedAt } }"#
      ))

    public var postId: ID

    public init(postId: ID) {
      self.postId = postId
    }

    public var __variables: Variables? { ["postId": postId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("postAttendanceCounts", [PostAttendanceCount].self, arguments: ["postId": .variable("postId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        PostAttendanceCountsQuery.Data.self
      ] }

      var postAttendanceCounts: [PostAttendanceCount] { __data["postAttendanceCounts"] }

      /// PostAttendanceCount
      ///
      /// Parent Type: `AttendanceCount`
      struct PostAttendanceCount: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AttendanceCount }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("count", Int.self),
          .field("section", String?.self),
          .field("notes", String?.self),
          .field("session", Session.self),
          .field("createdAt", AssemblyOpsAPI.DateTime.self),
          .field("updatedAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          PostAttendanceCountsQuery.Data.PostAttendanceCount.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var count: Int { __data["count"] }
        var section: String? { __data["section"] }
        var notes: String? { __data["notes"] }
        var session: Session { __data["session"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }
        var updatedAt: AssemblyOpsAPI.DateTime { __data["updatedAt"] }

        /// PostAttendanceCount.Session
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
            PostAttendanceCountsQuery.Data.PostAttendanceCount.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}