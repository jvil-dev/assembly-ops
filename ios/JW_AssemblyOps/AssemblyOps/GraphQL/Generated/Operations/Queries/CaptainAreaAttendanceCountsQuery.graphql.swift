// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CaptainAreaAttendanceCountsQuery: GraphQLQuery {
    static let operationName: String = "CaptainAreaAttendanceCounts"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query CaptainAreaAttendanceCounts($eventId: ID!) { captainAreaAttendanceCounts(eventId: $eventId) { __typename post { __typename id name location area { __typename id name } } session { __typename id name date } count section notes submittedBy { __typename id firstName lastName } submittedAt } }"#
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
        .field("captainAreaAttendanceCounts", [CaptainAreaAttendanceCount].self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CaptainAreaAttendanceCountsQuery.Data.self
      ] }

      var captainAreaAttendanceCounts: [CaptainAreaAttendanceCount] { __data["captainAreaAttendanceCounts"] }

      /// CaptainAreaAttendanceCount
      ///
      /// Parent Type: `CaptainAreaAttendanceCount`
      struct CaptainAreaAttendanceCount: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.CaptainAreaAttendanceCount }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("post", Post.self),
          .field("session", Session.self),
          .field("count", Int.self),
          .field("section", String?.self),
          .field("notes", String?.self),
          .field("submittedBy", SubmittedBy.self),
          .field("submittedAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CaptainAreaAttendanceCountsQuery.Data.CaptainAreaAttendanceCount.self
        ] }

        var post: Post { __data["post"] }
        var session: Session { __data["session"] }
        var count: Int { __data["count"] }
        var section: String? { __data["section"] }
        var notes: String? { __data["notes"] }
        var submittedBy: SubmittedBy { __data["submittedBy"] }
        var submittedAt: AssemblyOpsAPI.DateTime { __data["submittedAt"] }

        /// CaptainAreaAttendanceCount.Post
        ///
        /// Parent Type: `Post`
        struct Post: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Post }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
            .field("location", String?.self),
            .field("area", Area?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CaptainAreaAttendanceCountsQuery.Data.CaptainAreaAttendanceCount.Post.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var location: String? { __data["location"] }
          var area: Area? { __data["area"] }

          /// CaptainAreaAttendanceCount.Post.Area
          ///
          /// Parent Type: `Area`
          struct Area: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Area }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AssemblyOpsAPI.ID.self),
              .field("name", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              CaptainAreaAttendanceCountsQuery.Data.CaptainAreaAttendanceCount.Post.Area.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
          }
        }

        /// CaptainAreaAttendanceCount.Session
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
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CaptainAreaAttendanceCountsQuery.Data.CaptainAreaAttendanceCount.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var date: AssemblyOpsAPI.DateTime { __data["date"] }
        }

        /// CaptainAreaAttendanceCount.SubmittedBy
        ///
        /// Parent Type: `User`
        struct SubmittedBy: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.User }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("firstName", String.self),
            .field("lastName", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CaptainAreaAttendanceCountsQuery.Data.CaptainAreaAttendanceCount.SubmittedBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }
      }
    }
  }

}