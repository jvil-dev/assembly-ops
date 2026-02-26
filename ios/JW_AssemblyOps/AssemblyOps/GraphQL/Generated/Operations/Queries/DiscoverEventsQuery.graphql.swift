// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class DiscoverEventsQuery: GraphQLQuery {
    static let operationName: String = "DiscoverEvents"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query DiscoverEvents($eventType: EventType) { discoverEvents(eventType: $eventType) { __typename id name eventType venue address startDate endDate isPublic volunteerCount } }"#
      ))

    public var eventType: GraphQLNullable<GraphQLEnum<EventType>>

    public init(eventType: GraphQLNullable<GraphQLEnum<EventType>>) {
      self.eventType = eventType
    }

    public var __variables: Variables? { ["eventType": eventType] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("discoverEvents", [DiscoverEvent].self, arguments: ["eventType": .variable("eventType")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DiscoverEventsQuery.Data.self
      ] }

      var discoverEvents: [DiscoverEvent] { __data["discoverEvents"] }

      /// DiscoverEvent
      ///
      /// Parent Type: `Event`
      struct DiscoverEvent: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Event }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("eventType", GraphQLEnum<AssemblyOpsAPI.EventType>.self),
          .field("venue", String.self),
          .field("address", String.self),
          .field("startDate", AssemblyOpsAPI.DateTime.self),
          .field("endDate", AssemblyOpsAPI.DateTime.self),
          .field("isPublic", Bool.self),
          .field("volunteerCount", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          DiscoverEventsQuery.Data.DiscoverEvent.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var eventType: GraphQLEnum<AssemblyOpsAPI.EventType> { __data["eventType"] }
        var venue: String { __data["venue"] }
        var address: String { __data["address"] }
        var startDate: AssemblyOpsAPI.DateTime { __data["startDate"] }
        var endDate: AssemblyOpsAPI.DateTime { __data["endDate"] }
        var isPublic: Bool { __data["isPublic"] }
        var volunteerCount: Int { __data["volunteerCount"] }
      }
    }
  }

}