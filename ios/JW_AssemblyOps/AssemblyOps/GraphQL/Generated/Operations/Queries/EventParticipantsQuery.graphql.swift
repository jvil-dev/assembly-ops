// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class EventParticipantsQuery: GraphQLQuery {
    static let operationName: String = "EventParticipants"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query EventParticipants($eventId: ID!) { eventParticipants(eventId: $eventId) { __typename id displayName isAdmin } }"#
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
        .field("eventParticipants", [EventParticipant].self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        EventParticipantsQuery.Data.self
      ] }

      var eventParticipants: [EventParticipant] { __data["eventParticipants"] }

      /// EventParticipant
      ///
      /// Parent Type: `EventParticipant`
      struct EventParticipant: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventParticipant }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("displayName", String.self),
          .field("isAdmin", Bool.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          EventParticipantsQuery.Data.EventParticipant.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var displayName: String { __data["displayName"] }
        var isAdmin: Bool { __data["isAdmin"] }
      }
    }
  }

}