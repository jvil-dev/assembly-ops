// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MyAssignmentsQuery: GraphQLQuery {
    static let operationName: String = "MyAssignments"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query MyAssignments($eventId: ID!) { myAssignments(eventId: $eventId) { __typename id status isCaptain canCount respondedAt declineReason acceptDeadline forceAssigned post { __typename id name location category area { __typename id name } department { __typename id name departmentType event { __typename id } } } session { __typename id name date startTime endTime } shift { __typename id name startTime endTime } checkIn { __typename id status checkInTime checkOutTime } } }"#
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
        .field("myAssignments", [MyAssignment].self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MyAssignmentsQuery.Data.self
      ] }

      var myAssignments: [MyAssignment] { __data["myAssignments"] }

      /// MyAssignment
      ///
      /// Parent Type: `ScheduleAssignment`
      struct MyAssignment: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.ScheduleAssignment }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("status", GraphQLEnum<AssemblyOpsAPI.AssignmentStatus>.self),
          .field("isCaptain", Bool.self),
          .field("canCount", Bool.self),
          .field("respondedAt", AssemblyOpsAPI.DateTime?.self),
          .field("declineReason", String?.self),
          .field("acceptDeadline", AssemblyOpsAPI.DateTime?.self),
          .field("forceAssigned", Bool.self),
          .field("post", Post.self),
          .field("session", Session.self),
          .field("shift", Shift?.self),
          .field("checkIn", CheckIn?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MyAssignmentsQuery.Data.MyAssignment.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var status: GraphQLEnum<AssemblyOpsAPI.AssignmentStatus> { __data["status"] }
        var isCaptain: Bool { __data["isCaptain"] }
        var canCount: Bool { __data["canCount"] }
        var respondedAt: AssemblyOpsAPI.DateTime? { __data["respondedAt"] }
        var declineReason: String? { __data["declineReason"] }
        var acceptDeadline: AssemblyOpsAPI.DateTime? { __data["acceptDeadline"] }
        var forceAssigned: Bool { __data["forceAssigned"] }
        var post: Post { __data["post"] }
        var session: Session { __data["session"] }
        var shift: Shift? { __data["shift"] }
        var checkIn: CheckIn? { __data["checkIn"] }

        /// MyAssignment.Post
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
            .field("category", String?.self),
            .field("area", Area?.self),
            .field("department", Department.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MyAssignmentsQuery.Data.MyAssignment.Post.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var location: String? { __data["location"] }
          var category: String? { __data["category"] }
          var area: Area? { __data["area"] }
          var department: Department { __data["department"] }

          /// MyAssignment.Post.Area
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
              MyAssignmentsQuery.Data.MyAssignment.Post.Area.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
          }

          /// MyAssignment.Post.Department
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
              .field("event", Event.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              MyAssignmentsQuery.Data.MyAssignment.Post.Department.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
            var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType> { __data["departmentType"] }
            var event: Event { __data["event"] }

            /// MyAssignment.Post.Department.Event
            ///
            /// Parent Type: `Event`
            struct Event: AssemblyOpsAPI.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Event }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("id", AssemblyOpsAPI.ID.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                MyAssignmentsQuery.Data.MyAssignment.Post.Department.Event.self
              ] }

              var id: AssemblyOpsAPI.ID { __data["id"] }
            }
          }
        }

        /// MyAssignment.Session
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
            MyAssignmentsQuery.Data.MyAssignment.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var date: AssemblyOpsAPI.DateTime { __data["date"] }
          var startTime: AssemblyOpsAPI.DateTime { __data["startTime"] }
          var endTime: AssemblyOpsAPI.DateTime { __data["endTime"] }
        }

        /// MyAssignment.Shift
        ///
        /// Parent Type: `Shift`
        struct Shift: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Shift }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
            .field("startTime", AssemblyOpsAPI.DateTime.self),
            .field("endTime", AssemblyOpsAPI.DateTime.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MyAssignmentsQuery.Data.MyAssignment.Shift.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var startTime: AssemblyOpsAPI.DateTime { __data["startTime"] }
          var endTime: AssemblyOpsAPI.DateTime { __data["endTime"] }
        }

        /// MyAssignment.CheckIn
        ///
        /// Parent Type: `CheckIn`
        struct CheckIn: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.CheckIn }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("status", GraphQLEnum<AssemblyOpsAPI.CheckInStatus>.self),
            .field("checkInTime", AssemblyOpsAPI.DateTime.self),
            .field("checkOutTime", AssemblyOpsAPI.DateTime?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MyAssignmentsQuery.Data.MyAssignment.CheckIn.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var status: GraphQLEnum<AssemblyOpsAPI.CheckInStatus> { __data["status"] }
          var checkInTime: AssemblyOpsAPI.DateTime { __data["checkInTime"] }
          var checkOutTime: AssemblyOpsAPI.DateTime? { __data["checkOutTime"] }
        }
      }
    }
  }

}