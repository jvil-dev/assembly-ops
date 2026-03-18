// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class SendMultiMessageMutation: GraphQLMutation {
    static let operationName: String = "SendMultiMessage"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation SendMultiMessage($input: SendMultiMessageInput!) { sendMultiMessage(input: $input) { __typename id subject body recipientType senderType senderName recipientName createdAt } }"#
      ))

    public var input: SendMultiMessageInput

    public init(input: SendMultiMessageInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("sendMultiMessage", [SendMultiMessage].self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SendMultiMessageMutation.Data.self
      ] }

      var sendMultiMessage: [SendMultiMessage] { __data["sendMultiMessage"] }

      /// SendMultiMessage
      ///
      /// Parent Type: `Message`
      struct SendMultiMessage: AssemblyOpsAPI.SelectionSet {
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
          .field("createdAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SendMultiMessageMutation.Data.SendMultiMessage.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var subject: String? { __data["subject"] }
        var body: String { __data["body"] }
        var recipientType: GraphQLEnum<AssemblyOpsAPI.RecipientType> { __data["recipientType"] }
        var senderType: GraphQLEnum<AssemblyOpsAPI.MessageSenderType>? { __data["senderType"] }
        var senderName: String? { __data["senderName"] }
        var recipientName: String? { __data["recipientName"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }
      }
    }
  }

}