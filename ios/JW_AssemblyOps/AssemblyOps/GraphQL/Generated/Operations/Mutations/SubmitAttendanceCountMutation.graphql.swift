// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class SubmitAttendanceCountMutation: GraphQLMutation {
    static let operationName: String = "SubmitAttendanceCount"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation SubmitAttendanceCount($input: SubmitAttendanceCountInput!) { submitAttendanceCount(input: $input) { __typename id count notes session { __typename id name } createdAt } }"#
      ))

    public var input: SubmitAttendanceCountInput

    public init(input: SubmitAttendanceCountInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("submitAttendanceCount", SubmitAttendanceCount.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SubmitAttendanceCountMutation.Data.self
      ] }

      var submitAttendanceCount: SubmitAttendanceCount { __data["submitAttendanceCount"] }

      /// SubmitAttendanceCount
      ///
      /// Parent Type: `AttendanceCount`
      struct SubmitAttendanceCount: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AttendanceCount }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("count", Int.self),
          .field("notes", String?.self),
          .field("session", Session.self),
          .field("createdAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SubmitAttendanceCountMutation.Data.SubmitAttendanceCount.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var count: Int { __data["count"] }
        var notes: String? { __data["notes"] }
        var session: Session { __data["session"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }

        /// SubmitAttendanceCount.Session
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
            SubmitAttendanceCountMutation.Data.SubmitAttendanceCount.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}