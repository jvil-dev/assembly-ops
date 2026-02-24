// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class SearchMessagesQuery: GraphQLQuery {
    static let operationName: String = "SearchMessages"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SearchMessages($eventId: ID!, $query: String!, $limit: Int, $offset: Int) { searchMessages(eventId: $eventId, query: $query, limit: $limit, offset: $offset) { __typename id subject body recipientType senderType senderName senderId isRead readAt createdAt } }"#
      ))

    public var eventId: ID
    public var query: String
    public var limit: GraphQLNullable<Int>
    public var offset: GraphQLNullable<Int>

    public init(
      eventId: ID,
      query: String,
      limit: GraphQLNullable<Int>,
      offset: GraphQLNullable<Int>
    ) {
      self.eventId = eventId
      self.query = query
      self.limit = limit
      self.offset = offset
    }

    public var __variables: Variables? { [
      "eventId": eventId,
      "query": query,
      "limit": limit,
      "offset": offset
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("searchMessages", [SearchMessage].self, arguments: [
          "eventId": .variable("eventId"),
          "query": .variable("query"),
          "limit": .variable("limit"),
          "offset": .variable("offset")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SearchMessagesQuery.Data.self
      ] }

      var searchMessages: [SearchMessage] { __data["searchMessages"] }

      /// SearchMessage
      ///
      /// Parent Type: `Message`
      struct SearchMessage: AssemblyOpsAPI.SelectionSet {
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
          SearchMessagesQuery.Data.SearchMessage.self
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