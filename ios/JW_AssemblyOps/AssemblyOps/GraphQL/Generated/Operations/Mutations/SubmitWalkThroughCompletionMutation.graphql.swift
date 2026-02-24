// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class SubmitWalkThroughCompletionMutation: GraphQLMutation {
    static let operationName: String = "SubmitWalkThroughCompletion"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation SubmitWalkThroughCompletion($input: SubmitWalkThroughCompletionInput!) { submitWalkThroughCompletion(input: $input) { __typename id session { __typename id name } completedAt itemCount notes } }"#
      ))

    public var input: SubmitWalkThroughCompletionInput

    public init(input: SubmitWalkThroughCompletionInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("submitWalkThroughCompletion", SubmitWalkThroughCompletion.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SubmitWalkThroughCompletionMutation.Data.self
      ] }

      var submitWalkThroughCompletion: SubmitWalkThroughCompletion { __data["submitWalkThroughCompletion"] }

      /// SubmitWalkThroughCompletion
      ///
      /// Parent Type: `WalkThroughCompletion`
      struct SubmitWalkThroughCompletion: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.WalkThroughCompletion }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("session", Session.self),
          .field("completedAt", String.self),
          .field("itemCount", Int.self),
          .field("notes", String?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SubmitWalkThroughCompletionMutation.Data.SubmitWalkThroughCompletion.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var session: Session { __data["session"] }
        var completedAt: String { __data["completedAt"] }
        var itemCount: Int { __data["itemCount"] }
        var notes: String? { __data["notes"] }

        /// SubmitWalkThroughCompletion.Session
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
            SubmitWalkThroughCompletionMutation.Data.SubmitWalkThroughCompletion.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}