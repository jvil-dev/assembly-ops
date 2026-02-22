// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class VolunteerSessionsForEventQuery: GraphQLQuery {
    static let operationName: String = "VolunteerSessionsForEvent"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query VolunteerSessionsForEvent($eventId: ID!) { volunteerSessionsForEvent(eventId: $eventId) { __typename id name date startTime endTime } }"#
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
        .field("volunteerSessionsForEvent", [VolunteerSessionsForEvent].self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        VolunteerSessionsForEventQuery.Data.self
      ] }

      var volunteerSessionsForEvent: [VolunteerSessionsForEvent] { __data["volunteerSessionsForEvent"] }

      /// VolunteerSessionsForEvent
      ///
      /// Parent Type: `Session`
      struct VolunteerSessionsForEvent: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Session }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("date", AssemblyOpsAPI.DateTime.self),
          .field("startTime", AssemblyOpsAPI.DateTime.self),
          .field("endTime", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          VolunteerSessionsForEventQuery.Data.VolunteerSessionsForEvent.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var date: AssemblyOpsAPI.DateTime { __data["date"] }
        var startTime: AssemblyOpsAPI.DateTime { __data["startTime"] }
        var endTime: AssemblyOpsAPI.DateTime { __data["endTime"] }
      }
    }
  }

}