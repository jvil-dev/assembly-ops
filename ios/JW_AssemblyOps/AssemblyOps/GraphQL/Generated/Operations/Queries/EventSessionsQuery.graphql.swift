// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class EventSessionsQuery: GraphQLQuery {
    static let operationName: String = "EventSessions"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query EventSessions($eventId: ID!, $departmentId: ID) { sessions(eventId: $eventId, departmentId: $departmentId) { __typename id name date startTime endTime assignmentCount } }"#
      ))

    public var eventId: ID
    public var departmentId: GraphQLNullable<ID>

    public init(
      eventId: ID,
      departmentId: GraphQLNullable<ID>
    ) {
      self.eventId = eventId
      self.departmentId = departmentId
    }

    public var __variables: Variables? { [
      "eventId": eventId,
      "departmentId": departmentId
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("sessions", [Session].self, arguments: [
          "eventId": .variable("eventId"),
          "departmentId": .variable("departmentId")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        EventSessionsQuery.Data.self
      ] }

      var sessions: [Session] { __data["sessions"] }

      /// Session
      ///
      /// Parent Type: `Session`
      struct Session: AssemblyOpsAPI.SelectionSet {
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
          .field("assignmentCount", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          EventSessionsQuery.Data.Session.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var date: AssemblyOpsAPI.DateTime { __data["date"] }
        var startTime: AssemblyOpsAPI.DateTime { __data["startTime"] }
        var endTime: AssemblyOpsAPI.DateTime { __data["endTime"] }
        var assignmentCount: Int { __data["assignmentCount"] }
      }
    }
  }

}