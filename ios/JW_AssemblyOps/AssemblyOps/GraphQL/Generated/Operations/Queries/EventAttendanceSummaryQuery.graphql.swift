// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class EventAttendanceSummaryQuery: GraphQLQuery {
    static let operationName: String = "EventAttendanceSummary"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query EventAttendanceSummary($eventId: ID!) { eventAttendanceSummary(eventId: $eventId) { __typename session { __typename id name date startTime endTime } totalCount sectionCounts { __typename id count section notes submittedBy { __typename id firstName lastName } createdAt updatedAt } } }"#
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
        .field("eventAttendanceSummary", [EventAttendanceSummary].self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        EventAttendanceSummaryQuery.Data.self
      ] }

      var eventAttendanceSummary: [EventAttendanceSummary] { __data["eventAttendanceSummary"] }

      /// EventAttendanceSummary
      ///
      /// Parent Type: `SessionAttendanceSummary`
      struct EventAttendanceSummary: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.SessionAttendanceSummary }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("session", Session.self),
          .field("totalCount", Int.self),
          .field("sectionCounts", [SectionCount].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          EventAttendanceSummaryQuery.Data.EventAttendanceSummary.self
        ] }

        var session: Session { __data["session"] }
        var totalCount: Int { __data["totalCount"] }
        var sectionCounts: [SectionCount] { __data["sectionCounts"] }

        /// EventAttendanceSummary.Session
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
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            EventAttendanceSummaryQuery.Data.EventAttendanceSummary.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var date: AssemblyOpsAPI.DateTime { __data["date"] }
          var startTime: AssemblyOpsAPI.DateTime { __data["startTime"] }
          var endTime: AssemblyOpsAPI.DateTime { __data["endTime"] }
        }

        /// EventAttendanceSummary.SectionCount
        ///
        /// Parent Type: `AttendanceCount`
        struct SectionCount: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AttendanceCount }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("count", Int.self),
            .field("section", String?.self),
            .field("notes", String?.self),
            .field("submittedBy", SubmittedBy.self),
            .field("createdAt", AssemblyOpsAPI.DateTime.self),
            .field("updatedAt", AssemblyOpsAPI.DateTime.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            EventAttendanceSummaryQuery.Data.EventAttendanceSummary.SectionCount.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var count: Int { __data["count"] }
          var section: String? { __data["section"] }
          var notes: String? { __data["notes"] }
          var submittedBy: SubmittedBy { __data["submittedBy"] }
          var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }
          var updatedAt: AssemblyOpsAPI.DateTime { __data["updatedAt"] }

          /// EventAttendanceSummary.SectionCount.SubmittedBy
          ///
          /// Parent Type: `Admin`
          struct SubmittedBy: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Admin }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AssemblyOpsAPI.ID.self),
              .field("firstName", String.self),
              .field("lastName", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              EventAttendanceSummaryQuery.Data.EventAttendanceSummary.SectionCount.SubmittedBy.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var firstName: String { __data["firstName"] }
            var lastName: String { __data["lastName"] }
          }
        }
      }
    }
  }

}