// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MyNotificationsQuery: GraphQLQuery {
    static let operationName: String = "MyNotifications"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query MyNotifications($eventId: ID!, $limit: Int, $offset: Int) { myNotifications(eventId: $eventId, limit: $limit, offset: $offset) { __typename id type title body data isRead createdAt } }"#
      ))

    public var eventId: ID
    public var limit: GraphQLNullable<Int>
    public var offset: GraphQLNullable<Int>

    public init(
      eventId: ID,
      limit: GraphQLNullable<Int>,
      offset: GraphQLNullable<Int>
    ) {
      self.eventId = eventId
      self.limit = limit
      self.offset = offset
    }

    public var __variables: Variables? { [
      "eventId": eventId,
      "limit": limit,
      "offset": offset
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("myNotifications", [MyNotification].self, arguments: [
          "eventId": .variable("eventId"),
          "limit": .variable("limit"),
          "offset": .variable("offset")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MyNotificationsQuery.Data.self
      ] }

      var myNotifications: [MyNotification] { __data["myNotifications"] }

      /// MyNotification
      ///
      /// Parent Type: `Notification`
      struct MyNotification: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Notification }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("type", String.self),
          .field("title", String.self),
          .field("body", String.self),
          .field("data", String?.self),
          .field("isRead", Bool.self),
          .field("createdAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MyNotificationsQuery.Data.MyNotification.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var type: String { __data["type"] }
        var title: String { __data["title"] }
        var body: String { __data["body"] }
        var data: String? { __data["data"] }
        var isRead: Bool { __data["isRead"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }
      }
    }
  }

}