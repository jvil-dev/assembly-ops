// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MarkConversationReadMutation: GraphQLMutation {
    static let operationName: String = "MarkConversationRead"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation MarkConversationRead($id: ID!) { markConversationRead(id: $id) { __typename id unreadCount updatedAt } }"#
      ))

    public var id: ID

    public init(id: ID) {
      self.id = id
    }

    public var __variables: Variables? { ["id": id] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("markConversationRead", MarkConversationRead.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MarkConversationReadMutation.Data.self
      ] }

      var markConversationRead: MarkConversationRead { __data["markConversationRead"] }

      /// MarkConversationRead
      ///
      /// Parent Type: `Conversation`
      struct MarkConversationRead: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Conversation }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("unreadCount", Int.self),
          .field("updatedAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MarkConversationReadMutation.Data.MarkConversationRead.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var unreadCount: Int { __data["unreadCount"] }
        var updatedAt: AssemblyOpsAPI.DateTime { __data["updatedAt"] }
      }
    }
  }

}