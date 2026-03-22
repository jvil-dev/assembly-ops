// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class RequestPasswordResetMutation: GraphQLMutation {
    static let operationName: String = "RequestPasswordReset"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RequestPasswordReset($input: RequestPasswordResetInput!) { requestPasswordReset(input: $input) { __typename success } }"#
      ))

    public var input: RequestPasswordResetInput

    public init(input: RequestPasswordResetInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("requestPasswordReset", RequestPasswordReset.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RequestPasswordResetMutation.Data.self
      ] }

      var requestPasswordReset: RequestPasswordReset { __data["requestPasswordReset"] }

      /// RequestPasswordReset
      ///
      /// Parent Type: `RequestPasswordResetPayload`
      struct RequestPasswordReset: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.RequestPasswordResetPayload }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("success", Bool.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RequestPasswordResetMutation.Data.RequestPasswordReset.self
        ] }

        var success: Bool { __data["success"] }
      }
    }
  }

}