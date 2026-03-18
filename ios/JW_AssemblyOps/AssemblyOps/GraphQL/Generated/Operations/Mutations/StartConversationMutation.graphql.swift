// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class StartConversationMutation: GraphQLMutation {
    static let operationName: String = "StartConversation"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation StartConversation($input: StartConversationInput!) { startConversation(input: $input) { __typename id subject unreadCount createdAt updatedAt lastMessage { __typename id body senderName senderType createdAt } participants { __typename id participantType participantId displayName phone congregation lastReadAt } } }"#
      ))

    public var input: StartConversationInput

    public init(input: StartConversationInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("startConversation", StartConversation.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        StartConversationMutation.Data.self
      ] }

      var startConversation: StartConversation { __data["startConversation"] }

      /// StartConversation
      ///
      /// Parent Type: `Conversation`
      struct StartConversation: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Conversation }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("subject", String?.self),
          .field("unreadCount", Int.self),
          .field("createdAt", AssemblyOpsAPI.DateTime.self),
          .field("updatedAt", AssemblyOpsAPI.DateTime.self),
          .field("lastMessage", LastMessage?.self),
          .field("participants", [Participant].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          StartConversationMutation.Data.StartConversation.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var subject: String? { __data["subject"] }
        var unreadCount: Int { __data["unreadCount"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }
        var updatedAt: AssemblyOpsAPI.DateTime { __data["updatedAt"] }
        var lastMessage: LastMessage? { __data["lastMessage"] }
        var participants: [Participant] { __data["participants"] }

        /// StartConversation.LastMessage
        ///
        /// Parent Type: `Message`
        struct LastMessage: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Message }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("body", String.self),
            .field("senderName", String?.self),
            .field("senderType", GraphQLEnum<AssemblyOpsAPI.MessageSenderType>?.self),
            .field("createdAt", AssemblyOpsAPI.DateTime.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            StartConversationMutation.Data.StartConversation.LastMessage.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var body: String { __data["body"] }
          var senderName: String? { __data["senderName"] }
          var senderType: GraphQLEnum<AssemblyOpsAPI.MessageSenderType>? { __data["senderType"] }
          var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }
        }

        /// StartConversation.Participant
        ///
        /// Parent Type: `ConversationParticipant`
        struct Participant: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.ConversationParticipant }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("participantType", GraphQLEnum<AssemblyOpsAPI.MessageSenderType>.self),
            .field("participantId", AssemblyOpsAPI.ID.self),
            .field("displayName", String.self),
            .field("phone", String?.self),
            .field("congregation", String?.self),
            .field("lastReadAt", AssemblyOpsAPI.DateTime?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            StartConversationMutation.Data.StartConversation.Participant.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var participantType: GraphQLEnum<AssemblyOpsAPI.MessageSenderType> { __data["participantType"] }
          var participantId: AssemblyOpsAPI.ID { __data["participantId"] }
          var displayName: String { __data["displayName"] }
          var phone: String? { __data["phone"] }
          var congregation: String? { __data["congregation"] }
          var lastReadAt: AssemblyOpsAPI.DateTime? { __data["lastReadAt"] }
        }
      }
    }
  }

}