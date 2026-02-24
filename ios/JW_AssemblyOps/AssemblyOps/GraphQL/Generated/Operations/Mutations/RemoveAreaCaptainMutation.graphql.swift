// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class RemoveAreaCaptainMutation: GraphQLMutation {
    static let operationName: String = "RemoveAreaCaptain"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RemoveAreaCaptain($input: RemoveAreaCaptainInput!) { removeAreaCaptain(input: $input) }"#
      ))

    public var input: RemoveAreaCaptainInput

    public init(input: RemoveAreaCaptainInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("removeAreaCaptain", Bool.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RemoveAreaCaptainMutation.Data.self
      ] }

      var removeAreaCaptain: Bool { __data["removeAreaCaptain"] }
    }
  }

}