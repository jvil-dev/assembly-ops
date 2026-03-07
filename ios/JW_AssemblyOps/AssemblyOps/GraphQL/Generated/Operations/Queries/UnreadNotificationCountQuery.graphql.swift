// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class UnreadNotificationCountQuery: GraphQLQuery {
    static let operationName: String = "UnreadNotificationCount"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query UnreadNotificationCount($eventId: ID!) { unreadNotificationCount(eventId: $eventId) }"#
      ))

    public var eventId: ID

    public init(eventId: ID) {
      self.eventId = eventId
    }

    public var __variables: Variables? { ["eventId": eventId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("unreadNotificationCount", Int.self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UnreadNotificationCountQuery.Data.self
      ] }

      var unreadNotificationCount: Int { __data["unreadNotificationCount"] }
    }
  }

}