// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MarkAllNotificationsReadMutation: GraphQLMutation {
    static let operationName: String = "MarkAllNotificationsRead"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation MarkAllNotificationsRead($eventId: ID!) { markAllNotificationsRead(eventId: $eventId) }"#
      ))

    public var eventId: ID

    public init(eventId: ID) {
      self.eventId = eventId
    }

    public var __variables: Variables? { ["eventId": eventId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("markAllNotificationsRead", Bool.self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MarkAllNotificationsReadMutation.Data.self
      ] }

      var markAllNotificationsRead: Bool { __data["markAllNotificationsRead"] }
    }
  }

}