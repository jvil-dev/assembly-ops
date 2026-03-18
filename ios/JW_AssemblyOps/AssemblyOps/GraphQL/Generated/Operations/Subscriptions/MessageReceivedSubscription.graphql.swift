// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MessageReceivedSubscription: GraphQLSubscription {
    static let operationName: String = "MessageReceived"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"subscription MessageReceived($eventId: ID!) { messageReceived(eventId: $eventId) { __typename id subject body recipientType senderType senderName recipientName senderId isRead readAt conversation { __typename id } createdAt } }"#
      ))

    public var eventId: ID

    public init(eventId: ID) {
      self.eventId = eventId
    }

    public var __variables: Variables? { ["eventId": eventId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Subscription }
      static var __selections: [ApolloAPI.Selection] { [
        .field("messageReceived", MessageReceived.self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MessageReceivedSubscription.Data.self
      ] }

      var messageReceived: MessageReceived { __data["messageReceived"] }

      /// MessageReceived
      ///
      /// Parent Type: `Message`
      struct MessageReceived: AssemblyOpsAPI.SelectionSet {
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
          .field("recipientName", String?.self),
          .field("senderId", AssemblyOpsAPI.ID?.self),
          .field("isRead", Bool.self),
          .field("readAt", AssemblyOpsAPI.DateTime?.self),
          .field("conversation", Conversation?.self),
          .field("createdAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MessageReceivedSubscription.Data.MessageReceived.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var subject: String? { __data["subject"] }
        var body: String { __data["body"] }
        var recipientType: GraphQLEnum<AssemblyOpsAPI.RecipientType> { __data["recipientType"] }
        var senderType: GraphQLEnum<AssemblyOpsAPI.MessageSenderType>? { __data["senderType"] }
        var senderName: String? { __data["senderName"] }
        var recipientName: String? { __data["recipientName"] }
        var senderId: AssemblyOpsAPI.ID? { __data["senderId"] }
        var isRead: Bool { __data["isRead"] }
        var readAt: AssemblyOpsAPI.DateTime? { __data["readAt"] }
        var conversation: Conversation? { __data["conversation"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }

        /// MessageReceived.Conversation
        ///
        /// Parent Type: `Conversation`
        struct Conversation: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Conversation }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MessageReceivedSubscription.Data.MessageReceived.Conversation.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
        }
      }
    }
  }

}