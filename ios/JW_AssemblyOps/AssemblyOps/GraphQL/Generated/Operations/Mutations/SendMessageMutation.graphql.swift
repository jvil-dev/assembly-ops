// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class SendMessageMutation: GraphQLMutation {
    static let operationName: String = "SendMessage"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation SendMessage($input: SendMessageInput!) { sendMessage(input: $input) { __typename id subject body recipientType senderType senderName recipientName senderId conversation { __typename id } createdAt } }"#
      ))

    public var input: SendMessageInput

    public init(input: SendMessageInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("sendMessage", SendMessage.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SendMessageMutation.Data.self
      ] }

      var sendMessage: SendMessage { __data["sendMessage"] }

      /// SendMessage
      ///
      /// Parent Type: `Message`
      struct SendMessage: AssemblyOpsAPI.SelectionSet {
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
          .field("conversation", Conversation?.self),
          .field("createdAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SendMessageMutation.Data.SendMessage.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var subject: String? { __data["subject"] }
        var body: String { __data["body"] }
        var recipientType: GraphQLEnum<AssemblyOpsAPI.RecipientType> { __data["recipientType"] }
        var senderType: GraphQLEnum<AssemblyOpsAPI.MessageSenderType>? { __data["senderType"] }
        var senderName: String? { __data["senderName"] }
        var recipientName: String? { __data["recipientName"] }
        var senderId: AssemblyOpsAPI.ID? { __data["senderId"] }
        var conversation: Conversation? { __data["conversation"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }

        /// SendMessage.Conversation
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
            SendMessageMutation.Data.SendMessage.Conversation.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
        }
      }
    }
  }

}