// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class RegisterDeviceTokenMutation: GraphQLMutation {
    static let operationName: String = "RegisterDeviceToken"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RegisterDeviceToken($token: String!, $platform: String) { registerDeviceToken(token: $token, platform: $platform) }"#
      ))

    public var token: String
    public var platform: GraphQLNullable<String>

    public init(
      token: String,
      platform: GraphQLNullable<String>
    ) {
      self.token = token
      self.platform = platform
    }

    public var __variables: Variables? { [
      "token": token,
      "platform": platform
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("registerDeviceToken", Bool.self, arguments: [
          "token": .variable("token"),
          "platform": .variable("platform")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RegisterDeviceTokenMutation.Data.self
      ] }

      var registerDeviceToken: Bool { __data["registerDeviceToken"] }
    }
  }

}