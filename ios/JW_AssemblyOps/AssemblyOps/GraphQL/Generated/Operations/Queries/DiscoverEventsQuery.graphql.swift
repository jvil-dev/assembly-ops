// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class DiscoverEventsQuery: GraphQLQuery {
    static let operationName: String = "DiscoverEvents"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query DiscoverEvents($eventType: EventType, $state: String, $language: String, $circuitCode: String) { discoverEvents( eventType: $eventType state: $state language: $language circuitCode: $circuitCode ) { __typename id name eventType circuit state venue address startDate endDate theme isPublic volunteerCount departments { __typename id name departmentType volunteerCount } } }"#
      ))

    public var eventType: GraphQLNullable<GraphQLEnum<EventType>>
    public var state: GraphQLNullable<String>
    public var language: GraphQLNullable<String>
    public var circuitCode: GraphQLNullable<String>

    public init(
      eventType: GraphQLNullable<GraphQLEnum<EventType>>,
      state: GraphQLNullable<String>,
      language: GraphQLNullable<String>,
      circuitCode: GraphQLNullable<String>
    ) {
      self.eventType = eventType
      self.state = state
      self.language = language
      self.circuitCode = circuitCode
    }

    public var __variables: Variables? { [
      "eventType": eventType,
      "state": state,
      "language": language,
      "circuitCode": circuitCode
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("discoverEvents", [DiscoverEvent].self, arguments: [
          "eventType": .variable("eventType"),
          "state": .variable("state"),
          "language": .variable("language"),
          "circuitCode": .variable("circuitCode")
        ]),
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
          .field("circuit", String?.self),
          .field("state", String?.self),
          .field("venue", String.self),
          .field("address", String.self),
          .field("startDate", AssemblyOpsAPI.DateTime.self),
          .field("endDate", AssemblyOpsAPI.DateTime.self),
          .field("theme", String?.self),
          .field("isPublic", Bool.self),
          .field("volunteerCount", Int.self),
          .field("departments", [Department].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          DiscoverEventsQuery.Data.DiscoverEvent.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var eventType: GraphQLEnum<AssemblyOpsAPI.EventType> { __data["eventType"] }
        var circuit: String? { __data["circuit"] }
        var state: String? { __data["state"] }
        var venue: String { __data["venue"] }
        var address: String { __data["address"] }
        var startDate: AssemblyOpsAPI.DateTime { __data["startDate"] }
        var endDate: AssemblyOpsAPI.DateTime { __data["endDate"] }
        var theme: String? { __data["theme"] }
        var isPublic: Bool { __data["isPublic"] }
        var volunteerCount: Int { __data["volunteerCount"] }
        var departments: [Department] { __data["departments"] }

        /// DiscoverEvent.Department
        ///
        /// Parent Type: `Department`
        struct Department: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Department }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
            .field("departmentType", GraphQLEnum<AssemblyOpsAPI.DepartmentType>.self),
            .field("volunteerCount", Int.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            DiscoverEventsQuery.Data.DiscoverEvent.Department.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType> { __data["departmentType"] }
          var volunteerCount: Int { __data["volunteerCount"] }
        }
      }
    }
  }

}