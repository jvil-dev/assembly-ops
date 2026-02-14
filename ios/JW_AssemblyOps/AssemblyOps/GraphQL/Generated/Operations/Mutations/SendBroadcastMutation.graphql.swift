// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class SendBroadcastMutation: GraphQLMutation {
    static let operationName: String = "SendBroadcast"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation SendBroadcast($input: SendBroadcastInput!) { sendBroadcast(input: $input) { __typename id subject body recipientType createdAt } }"#
      ))

    public var input: SendBroadcastInput

    public init(input: SendBroadcastInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("sendBroadcast", [SendBroadcast].self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SendBroadcastMutation.Data.self
      ] }

      var sendBroadcast: [SendBroadcast] { __data["sendBroadcast"] }

      /// SendBroadcast
      ///
      /// Parent Type: `Message`
      struct SendBroadcast: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Message }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("subject", String?.self),
          .field("body", String.self),
          .field("recipientType", GraphQLEnum<AssemblyOpsAPI.RecipientType>.self),
          .field("createdAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SendBroadcastMutation.Data.SendBroadcast.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var subject: String? { __data["subject"] }
        var body: String { __data["body"] }
        var recipientType: GraphQLEnum<AssemblyOpsAPI.RecipientType> { __data["recipientType"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }
      }
    }
  }

}