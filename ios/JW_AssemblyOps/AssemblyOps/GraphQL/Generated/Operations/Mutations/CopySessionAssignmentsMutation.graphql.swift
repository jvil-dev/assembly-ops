// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CopySessionAssignmentsMutation: GraphQLMutation {
    static let operationName: String = "CopySessionAssignments"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CopySessionAssignments($input: CopySessionAssignmentsInput!) { copySessionAssignments(input: $input) { __typename copiedCount skippedCount skippedVolunteers { __typename volunteerName postName reason } copiedAreaCaptains } }"#
      ))

    public var input: CopySessionAssignmentsInput

    public init(input: CopySessionAssignmentsInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("copySessionAssignments", CopySessionAssignments.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CopySessionAssignmentsMutation.Data.self
      ] }

      var copySessionAssignments: CopySessionAssignments { __data["copySessionAssignments"] }

      /// CopySessionAssignments
      ///
      /// Parent Type: `CopySessionAssignmentsResult`
      struct CopySessionAssignments: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.CopySessionAssignmentsResult }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("copiedCount", Int.self),
          .field("skippedCount", Int.self),
          .field("skippedVolunteers", [SkippedVolunteer].self),
          .field("copiedAreaCaptains", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CopySessionAssignmentsMutation.Data.CopySessionAssignments.self
        ] }

        var copiedCount: Int { __data["copiedCount"] }
        var skippedCount: Int { __data["skippedCount"] }
        var skippedVolunteers: [SkippedVolunteer] { __data["skippedVolunteers"] }
        var copiedAreaCaptains: Int { __data["copiedAreaCaptains"] }

        /// CopySessionAssignments.SkippedVolunteer
        ///
        /// Parent Type: `SkippedVolunteerInfo`
        struct SkippedVolunteer: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.SkippedVolunteerInfo }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("volunteerName", String.self),
            .field("postName", String.self),
            .field("reason", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CopySessionAssignmentsMutation.Data.CopySessionAssignments.SkippedVolunteer.self
          ] }

          var volunteerName: String { __data["volunteerName"] }
          var postName: String { __data["postName"] }
          var reason: String { __data["reason"] }
        }
      }
    }
  }

}