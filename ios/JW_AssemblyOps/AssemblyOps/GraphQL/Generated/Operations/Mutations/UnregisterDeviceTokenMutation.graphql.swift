// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class UnregisterDeviceTokenMutation: GraphQLMutation {
    static let operationName: String = "UnregisterDeviceToken"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UnregisterDeviceToken($token: String!) { unregisterDeviceToken(token: $token) }"#
      ))

    public var token: String

    public init(token: String) {
      self.token = token
    }

    public var __variables: Variables? { ["token": token] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("unregisterDeviceToken", Bool.self, arguments: ["token": .variable("token")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UnregisterDeviceTokenMutation.Data.self
      ] }

      var unregisterDeviceToken: Bool { __data["unregisterDeviceToken"] }
    }
  }

}