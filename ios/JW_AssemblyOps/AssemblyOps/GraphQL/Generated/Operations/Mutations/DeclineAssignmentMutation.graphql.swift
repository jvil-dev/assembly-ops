// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class DeclineAssignmentMutation: GraphQLMutation {
    static let operationName: String = "DeclineAssignment"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation DeclineAssignment($input: DeclineAssignmentInput!) { declineAssignment(input: $input) { __typename id status respondedAt declineReason } }"#
      ))

    public var input: DeclineAssignmentInput

    public init(input: DeclineAssignmentInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("declineAssignment", DeclineAssignment.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DeclineAssignmentMutation.Data.self
      ] }

      var declineAssignment: DeclineAssignment { __data["declineAssignment"] }

      /// DeclineAssignment
      ///
      /// Parent Type: `ScheduleAssignment`
      struct DeclineAssignment: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.ScheduleAssignment }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("status", GraphQLEnum<AssemblyOpsAPI.AssignmentStatus>.self),
          .field("respondedAt", AssemblyOpsAPI.DateTime?.self),
          .field("declineReason", String?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          DeclineAssignmentMutation.Data.DeclineAssignment.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var status: GraphQLEnum<AssemblyOpsAPI.AssignmentStatus> { __data["status"] }
        var respondedAt: AssemblyOpsAPI.DateTime? { __data["respondedAt"] }
        var declineReason: String? { __data["declineReason"] }
      }
    }
  }

}