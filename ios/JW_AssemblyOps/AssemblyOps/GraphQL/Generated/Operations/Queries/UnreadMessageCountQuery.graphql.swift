// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class UnreadMessageCountQuery: GraphQLQuery {
    static let operationName: String = "UnreadMessageCount"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query UnreadMessageCount { unreadMessageCount }"#
      ))

    public init() {}

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("unreadMessageCount", Int.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UnreadMessageCountQuery.Data.self
      ] }

      var unreadMessageCount: Int { __data["unreadMessageCount"] }
    }
  }

}