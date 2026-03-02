// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class EventDetailsQuery: GraphQLQuery {
    static let operationName: String = "EventDetails"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query EventDetails($eventId: ID!) { event(id: $eventId) { __typename id name eventType venue address startDate endDate joinCode volunteerCount departments { __typename id name departmentType description volunteerCount isClaimed overseer { __typename id user { __typename id fullName } } posts { __typename id name description location } } sessions { __typename id name date startTime endTime } } }"#
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
        .field("event", Event?.self, arguments: ["id": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        EventDetailsQuery.Data.self
      ] }

      var event: Event? { __data["event"] }

      /// Event
      ///
      /// Parent Type: `Event`
      struct Event: AssemblyOpsAPI.SelectionSet {
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
          .field("joinCode", String.self),
          .field("volunteerCount", Int.self),
          .field("departments", [Department].self),
          .field("sessions", [Session].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          EventDetailsQuery.Data.Event.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var eventType: GraphQLEnum<AssemblyOpsAPI.EventType> { __data["eventType"] }
        var venue: String { __data["venue"] }
        var address: String { __data["address"] }
        var startDate: AssemblyOpsAPI.DateTime { __data["startDate"] }
        var endDate: AssemblyOpsAPI.DateTime { __data["endDate"] }
        var joinCode: String { __data["joinCode"] }
        var volunteerCount: Int { __data["volunteerCount"] }
        var departments: [Department] { __data["departments"] }
        var sessions: [Session] { __data["sessions"] }

        /// Event.Department
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
            .field("description", String?.self),
            .field("volunteerCount", Int.self),
            .field("isClaimed", Bool.self),
            .field("overseer", Overseer?.self),
            .field("posts", [Post].self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            EventDetailsQuery.Data.Event.Department.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType> { __data["departmentType"] }
          var description: String? { __data["description"] }
          var volunteerCount: Int { __data["volunteerCount"] }
          var isClaimed: Bool { __data["isClaimed"] }
          var overseer: Overseer? { __data["overseer"] }
          var posts: [Post] { __data["posts"] }

          /// Event.Department.Overseer
          ///
          /// Parent Type: `EventAdmin`
          struct Overseer: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventAdmin }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AssemblyOpsAPI.ID.self),
              .field("user", User.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              EventDetailsQuery.Data.Event.Department.Overseer.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var user: User { __data["user"] }

            /// Event.Department.Overseer.User
            ///
            /// Parent Type: `User`
            struct User: AssemblyOpsAPI.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.User }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("id", AssemblyOpsAPI.ID.self),
                .field("fullName", String.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                EventDetailsQuery.Data.Event.Department.Overseer.User.self
              ] }

              var id: AssemblyOpsAPI.ID { __data["id"] }
              var fullName: String { __data["fullName"] }
            }
          }

          /// Event.Department.Post
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
              .field("description", String?.self),
              .field("location", String?.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              EventDetailsQuery.Data.Event.Department.Post.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
            var description: String? { __data["description"] }
            var location: String? { __data["location"] }
          }
        }

        /// Event.Session
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
            EventDetailsQuery.Data.Event.Session.self
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

}