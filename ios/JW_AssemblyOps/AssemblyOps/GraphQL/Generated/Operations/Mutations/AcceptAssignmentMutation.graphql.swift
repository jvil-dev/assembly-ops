// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class AcceptAssignmentMutation: GraphQLMutation {
    static let operationName: String = "AcceptAssignment"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation AcceptAssignment($input: AcceptAssignmentInput!) { acceptAssignment(input: $input) { __typename id status respondedAt } }"#
      ))

    public var input: AcceptAssignmentInput

    public init(input: AcceptAssignmentInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("acceptAssignment", AcceptAssignment.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AcceptAssignmentMutation.Data.self
      ] }

      var acceptAssignment: AcceptAssignment { __data["acceptAssignment"] }

      /// AcceptAssignment
      ///
      /// Parent Type: `ScheduleAssignment`
      struct AcceptAssignment: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.ScheduleAssignment }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("status", GraphQLEnum<AssemblyOpsAPI.AssignmentStatus>.self),
          .field("respondedAt", AssemblyOpsAPI.DateTime?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AcceptAssignmentMutation.Data.AcceptAssignment.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var status: GraphQLEnum<AssemblyOpsAPI.AssignmentStatus> { __data["status"] }
        var respondedAt: AssemblyOpsAPI.DateTime? { __data["respondedAt"] }
      }
    }
  }

}