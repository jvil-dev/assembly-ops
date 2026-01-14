// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MyMessagesQuery: GraphQLQuery {
    static let operationName: String = "MyMessages"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query MyMessages($filter: MessageFilterInput, $limit: Int, $offset: Int) { myMessages(filter: $filter, limit: $limit, offset: $offset) { __typename id subject body recipientType isRead readAt createdAt sender { __typename id firstName lastName } } }"#
      ))

    public var filter: GraphQLNullable<MessageFilterInput>
    public var limit: GraphQLNullable<Int>
    public var offset: GraphQLNullable<Int>

    public init(
      filter: GraphQLNullable<MessageFilterInput>,
      limit: GraphQLNullable<Int>,
      offset: GraphQLNullable<Int>
    ) {
      self.filter = filter
      self.limit = limit
      self.offset = offset
    }

    public var __variables: Variables? { [
      "filter": filter,
      "limit": limit,
      "offset": offset
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("myMessages", [MyMessage].self, arguments: [
          "filter": .variable("filter"),
          "limit": .variable("limit"),
          "offset": .variable("offset")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MyMessagesQuery.Data.self
      ] }

      var myMessages: [MyMessage] { __data["myMessages"] }

      /// MyMessage
      ///
      /// Parent Type: `Message`
      struct MyMessage: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Message }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("subject", String?.self),
          .field("body", String.self),
          .field("recipientType", GraphQLEnum<AssemblyOpsAPI.RecipientType>.self),
          .field("isRead", Bool.self),
          .field("readAt", AssemblyOpsAPI.DateTime?.self),
          .field("createdAt", AssemblyOpsAPI.DateTime.self),
          .field("sender", Sender?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MyMessagesQuery.Data.MyMessage.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var subject: String? { __data["subject"] }
        var body: String { __data["body"] }
        var recipientType: GraphQLEnum<AssemblyOpsAPI.RecipientType> { __data["recipientType"] }
        var isRead: Bool { __data["isRead"] }
        var readAt: AssemblyOpsAPI.DateTime? { __data["readAt"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }
        var sender: Sender? { __data["sender"] }

        /// MyMessage.Sender
        ///
        /// Parent Type: `Admin`
        struct Sender: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Admin }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("firstName", String.self),
            .field("lastName", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MyMessagesQuery.Data.MyMessage.Sender.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }
      }
    }
  }

}