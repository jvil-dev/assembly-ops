// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class SendMessageMutation: GraphQLMutation {
    static let operationName: String = "SendMessage"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation SendMessage($input: SendMessageInput!) { sendMessage(input: $input) { __typename id subject body recipientType volunteer { __typename id firstName lastName } createdAt } }"#
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
          .field("volunteer", Volunteer?.self),
          .field("createdAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SendMessageMutation.Data.SendMessage.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var subject: String? { __data["subject"] }
        var body: String { __data["body"] }
        var recipientType: GraphQLEnum<AssemblyOpsAPI.RecipientType> { __data["recipientType"] }
        var volunteer: Volunteer? { __data["volunteer"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }

        /// SendMessage.Volunteer
        ///
        /// Parent Type: `Volunteer`
        struct Volunteer: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Volunteer }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("firstName", String.self),
            .field("lastName", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SendMessageMutation.Data.SendMessage.Volunteer.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }
      }
    }
  }

}