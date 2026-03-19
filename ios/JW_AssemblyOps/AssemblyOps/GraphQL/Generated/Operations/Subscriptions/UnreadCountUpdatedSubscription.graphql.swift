// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class UnreadCountUpdatedSubscription: GraphQLSubscription {
    static let operationName: String = "UnreadCountUpdated"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"subscription UnreadCountUpdated { unreadCountUpdated }"#
      ))

    public init() {}

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Subscription }
      static var __selections: [ApolloAPI.Selection] { [
        .field("unreadCountUpdated", Int.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UnreadCountUpdatedSubscription.Data.self
      ] }

      var unreadCountUpdated: Int { __data["unreadCountUpdated"] }
    }
  }

}