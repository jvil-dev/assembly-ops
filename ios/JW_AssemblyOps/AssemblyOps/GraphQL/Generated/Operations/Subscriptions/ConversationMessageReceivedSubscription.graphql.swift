// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class ConversationMessageReceivedSubscription: GraphQLSubscription {
    static let operationName: String = "ConversationMessageReceived"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"subscription ConversationMessageReceived($conversationId: ID!) { conversationMessageReceived(conversationId: $conversationId) { __typename id subject body recipientType senderType senderName senderId isRead readAt createdAt } }"#
      ))

    public var conversationId: ID

    public init(conversationId: ID) {
      self.conversationId = conversationId
    }

    public var __variables: Variables? { ["conversationId": conversationId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Subscription }
      static var __selections: [ApolloAPI.Selection] { [
        .field("conversationMessageReceived", ConversationMessageReceived.self, arguments: ["conversationId": .variable("conversationId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ConversationMessageReceivedSubscription.Data.self
      ] }

      var conversationMessageReceived: ConversationMessageReceived { __data["conversationMessageReceived"] }

      /// ConversationMessageReceived
      ///
      /// Parent Type: `Message`
      struct ConversationMessageReceived: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Message }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("subject", String?.self),
          .field("body", String.self),
          .field("recipientType", GraphQLEnum<AssemblyOpsAPI.RecipientType>.self),
          .field("senderType", GraphQLEnum<AssemblyOpsAPI.MessageSenderType>?.self),
          .field("senderName", String?.self),
          .field("senderId", AssemblyOpsAPI.ID?.self),
          .field("isRead", Bool.self),
          .field("readAt", AssemblyOpsAPI.DateTime?.self),
          .field("createdAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ConversationMessageReceivedSubscription.Data.ConversationMessageReceived.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var subject: String? { __data["subject"] }
        var body: String { __data["body"] }
        var recipientType: GraphQLEnum<AssemblyOpsAPI.RecipientType> { __data["recipientType"] }
        var senderType: GraphQLEnum<AssemblyOpsAPI.MessageSenderType>? { __data["senderType"] }
        var senderName: String? { __data["senderName"] }
        var senderId: AssemblyOpsAPI.ID? { __data["senderId"] }
        var isRead: Bool { __data["isRead"] }
        var readAt: AssemblyOpsAPI.DateTime? { __data["readAt"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }
      }
    }
  }

}