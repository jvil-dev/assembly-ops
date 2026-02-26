// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CancelJoinRequestMutation: GraphQLMutation {
    static let operationName: String = "CancelJoinRequest"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CancelJoinRequest($requestId: ID!) { cancelJoinRequest(requestId: $requestId) }"#
      ))

    public var requestId: ID

    public init(requestId: ID) {
      self.requestId = requestId
    }

    public var __variables: Variables? { ["requestId": requestId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("cancelJoinRequest", Bool.self, arguments: ["requestId": .variable("requestId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CancelJoinRequestMutation.Data.self
      ] }

      var cancelJoinRequest: Bool { __data["cancelJoinRequest"] }
    }
  }

}