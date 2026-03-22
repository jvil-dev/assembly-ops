// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class VerifyResetCodeMutation: GraphQLMutation {
    static let operationName: String = "VerifyResetCode"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation VerifyResetCode($input: VerifyResetCodeInput!) { verifyResetCode(input: $input) { __typename resetToken } }"#
      ))

    public var input: VerifyResetCodeInput

    public init(input: VerifyResetCodeInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("verifyResetCode", VerifyResetCode.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        VerifyResetCodeMutation.Data.self
      ] }

      var verifyResetCode: VerifyResetCode { __data["verifyResetCode"] }

      /// VerifyResetCode
      ///
      /// Parent Type: `VerifyResetCodePayload`
      struct VerifyResetCode: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.VerifyResetCodePayload }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("resetToken", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          VerifyResetCodeMutation.Data.VerifyResetCode.self
        ] }

        var resetToken: String { __data["resetToken"] }
      }
    }
  }

}