// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CaptainSessionsQuery: GraphQLQuery {
    static let operationName: String = "CaptainSessions"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query CaptainSessions($eventId: ID!) { captainSessions(eventId: $eventId) { __typename id name date startTime endTime assignmentCount } }"#
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
        .field("captainSessions", [CaptainSession].self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CaptainSessionsQuery.Data.self
      ] }

      var captainSessions: [CaptainSession] { __data["captainSessions"] }

      /// CaptainSession
      ///
      /// Parent Type: `Session`
      struct CaptainSession: AssemblyOpsAPI.SelectionSet {
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
          CaptainSessionsQuery.Data.CaptainSession.self
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