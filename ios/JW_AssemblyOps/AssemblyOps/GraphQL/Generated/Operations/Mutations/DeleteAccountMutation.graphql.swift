// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class DeleteAccountMutation: GraphQLMutation {
    static let operationName: String = "DeleteAccount"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation DeleteAccount($password: String) { deleteAccount(password: $password) }"#
      ))

    public var password: GraphQLNullable<String>

    public init(password: GraphQLNullable<String>) {
      self.password = password
    }

    public var __variables: Variables? { ["password": password] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("deleteAccount", Bool.self, arguments: ["password": .variable("password")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DeleteAccountMutation.Data.self
      ] }

      var deleteAccount: Bool { __data["deleteAccount"] }
    }
  }

}