// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class UpdateAttendanceCountMutation: GraphQLMutation {
    static let operationName: String = "UpdateAttendanceCount"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UpdateAttendanceCount($id: ID!, $input: UpdateAttendanceCountInput!) { updateAttendanceCount(id: $id, input: $input) { __typename id count notes updatedAt } }"#
      ))

    public var id: ID
    public var input: UpdateAttendanceCountInput

    public init(
      id: ID,
      input: UpdateAttendanceCountInput
    ) {
      self.id = id
      self.input = input
    }

    public var __variables: Variables? { [
      "id": id,
      "input": input
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("updateAttendanceCount", UpdateAttendanceCount.self, arguments: [
          "id": .variable("id"),
          "input": .variable("input")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UpdateAttendanceCountMutation.Data.self
      ] }

      var updateAttendanceCount: UpdateAttendanceCount { __data["updateAttendanceCount"] }

      /// UpdateAttendanceCount
      ///
      /// Parent Type: `AttendanceCount`
      struct UpdateAttendanceCount: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AttendanceCount }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("count", Int.self),
          .field("notes", String?.self),
          .field("updatedAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          UpdateAttendanceCountMutation.Data.UpdateAttendanceCount.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var count: Int { __data["count"] }
        var notes: String? { __data["notes"] }
        var updatedAt: AssemblyOpsAPI.DateTime { __data["updatedAt"] }
      }
    }
  }

}