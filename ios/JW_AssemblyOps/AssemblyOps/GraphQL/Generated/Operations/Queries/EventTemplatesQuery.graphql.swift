// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class EventTemplatesQuery: GraphQLQuery {
    static let operationName: String = "EventTemplates"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query EventTemplates($serviceYear: Int) { eventTemplates(serviceYear: $serviceYear) { __typename id eventType circuit region serviceYear name theme themeScripture venue address startDate endDate language isActivated } }"#
      ))

    public var serviceYear: GraphQLNullable<Int>

    public init(serviceYear: GraphQLNullable<Int>) {
      self.serviceYear = serviceYear
    }

    public var __variables: Variables? { ["serviceYear": serviceYear] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("eventTemplates", [EventTemplate].self, arguments: ["serviceYear": .variable("serviceYear")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        EventTemplatesQuery.Data.self
      ] }

      var eventTemplates: [EventTemplate] { __data["eventTemplates"] }

      /// EventTemplate
      ///
      /// Parent Type: `EventTemplate`
      struct EventTemplate: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventTemplate }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("eventType", GraphQLEnum<AssemblyOpsAPI.EventType>.self),
          .field("circuit", String?.self),
          .field("region", String.self),
          .field("serviceYear", Int.self),
          .field("name", String.self),
          .field("theme", String?.self),
          .field("themeScripture", String?.self),
          .field("venue", String.self),
          .field("address", String.self),
          .field("startDate", AssemblyOpsAPI.DateTime.self),
          .field("endDate", AssemblyOpsAPI.DateTime.self),
          .field("language", String.self),
          .field("isActivated", Bool.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          EventTemplatesQuery.Data.EventTemplate.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var eventType: GraphQLEnum<AssemblyOpsAPI.EventType> { __data["eventType"] }
        var circuit: String? { __data["circuit"] }
        var region: String { __data["region"] }
        var serviceYear: Int { __data["serviceYear"] }
        var name: String { __data["name"] }
        var theme: String? { __data["theme"] }
        var themeScripture: String? { __data["themeScripture"] }
        var venue: String { __data["venue"] }
        var address: String { __data["address"] }
        var startDate: AssemblyOpsAPI.DateTime { __data["startDate"] }
        var endDate: AssemblyOpsAPI.DateTime { __data["endDate"] }
        var language: String { __data["language"] }
        var isActivated: Bool { __data["isActivated"] }
      }
    }
  }

}