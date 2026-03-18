// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class SendDepartmentMessageMutation: GraphQLMutation {
    static let operationName: String = "SendDepartmentMessage"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation SendDepartmentMessage($input: SendDepartmentMessageInput!) { sendDepartmentMessage(input: $input) { __typename id type subject updatedAt } }"#
      ))

    public var input: SendDepartmentMessageInput

    public init(input: SendDepartmentMessageInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("sendDepartmentMessage", SendDepartmentMessage.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SendDepartmentMessageMutation.Data.self
      ] }

      var sendDepartmentMessage: SendDepartmentMessage { __data["sendDepartmentMessage"] }

      /// SendDepartmentMessage
      ///
      /// Parent Type: `Conversation`
      struct SendDepartmentMessage: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Conversation }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("type", GraphQLEnum<AssemblyOpsAPI.ConversationType>.self),
          .field("subject", String?.self),
          .field("updatedAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SendDepartmentMessageMutation.Data.SendDepartmentMessage.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var type: GraphQLEnum<AssemblyOpsAPI.ConversationType> { __data["type"] }
        var subject: String? { __data["subject"] }
        var updatedAt: AssemblyOpsAPI.DateTime { __data["updatedAt"] }
      }
    }
  }

}