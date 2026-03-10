// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MyCaptainAssignmentsQuery: GraphQLQuery {
    static let operationName: String = "MyCaptainAssignments"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query MyCaptainAssignments($eventId: ID!) { myCaptainAssignments(eventId: $eventId) { __typename id status respondedAt declineReason acceptedDeadline forceAssigned area { __typename id name description category department { __typename id name departmentType event { __typename id } } } session { __typename id name date startTime endTime departmentSession { __typename startTime endTime } } eventVolunteer { __typename id user { __typename id firstName lastName } } createdAt } }"#
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
        .field("myCaptainAssignments", [MyCaptainAssignment].self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MyCaptainAssignmentsQuery.Data.self
      ] }

      var myCaptainAssignments: [MyCaptainAssignment] { __data["myCaptainAssignments"] }

      /// MyCaptainAssignment
      ///
      /// Parent Type: `AreaCaptainAssignment`
      struct MyCaptainAssignment: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AreaCaptainAssignment }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("status", GraphQLEnum<AssemblyOpsAPI.AssignmentStatus>.self),
          .field("respondedAt", AssemblyOpsAPI.DateTime?.self),
          .field("declineReason", String?.self),
          .field("acceptedDeadline", AssemblyOpsAPI.DateTime?.self),
          .field("forceAssigned", Bool.self),
          .field("area", Area.self),
          .field("session", Session.self),
          .field("eventVolunteer", EventVolunteer.self),
          .field("createdAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MyCaptainAssignmentsQuery.Data.MyCaptainAssignment.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var status: GraphQLEnum<AssemblyOpsAPI.AssignmentStatus> { __data["status"] }
        var respondedAt: AssemblyOpsAPI.DateTime? { __data["respondedAt"] }
        var declineReason: String? { __data["declineReason"] }
        var acceptedDeadline: AssemblyOpsAPI.DateTime? { __data["acceptedDeadline"] }
        var forceAssigned: Bool { __data["forceAssigned"] }
        var area: Area { __data["area"] }
        var session: Session { __data["session"] }
        var eventVolunteer: EventVolunteer { __data["eventVolunteer"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }

        /// MyCaptainAssignment.Area
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
            .field("description", String?.self),
            .field("category", String?.self),
            .field("department", Department.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MyCaptainAssignmentsQuery.Data.MyCaptainAssignment.Area.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var description: String? { __data["description"] }
          var category: String? { __data["category"] }
          var department: Department { __data["department"] }

          /// MyCaptainAssignment.Area.Department
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
              MyCaptainAssignmentsQuery.Data.MyCaptainAssignment.Area.Department.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
            var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType> { __data["departmentType"] }
            var event: Event { __data["event"] }

            /// MyCaptainAssignment.Area.Department.Event
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
                MyCaptainAssignmentsQuery.Data.MyCaptainAssignment.Area.Department.Event.self
              ] }

              var id: AssemblyOpsAPI.ID { __data["id"] }
            }
          }
        }

        /// MyCaptainAssignment.Session
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
            .field("departmentSession", DepartmentSession?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MyCaptainAssignmentsQuery.Data.MyCaptainAssignment.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var date: AssemblyOpsAPI.DateTime { __data["date"] }
          var startTime: AssemblyOpsAPI.DateTime { __data["startTime"] }
          var endTime: AssemblyOpsAPI.DateTime { __data["endTime"] }
          var departmentSession: DepartmentSession? { __data["departmentSession"] }

          /// MyCaptainAssignment.Session.DepartmentSession
          ///
          /// Parent Type: `DepartmentSession`
          struct DepartmentSession: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.DepartmentSession }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("startTime", AssemblyOpsAPI.DateTime?.self),
              .field("endTime", AssemblyOpsAPI.DateTime?.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              MyCaptainAssignmentsQuery.Data.MyCaptainAssignment.Session.DepartmentSession.self
            ] }

            var startTime: AssemblyOpsAPI.DateTime? { __data["startTime"] }
            var endTime: AssemblyOpsAPI.DateTime? { __data["endTime"] }
          }
        }

        /// MyCaptainAssignment.EventVolunteer
        ///
        /// Parent Type: `EventVolunteer`
        struct EventVolunteer: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventVolunteer }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("user", User.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MyCaptainAssignmentsQuery.Data.MyCaptainAssignment.EventVolunteer.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var user: User { __data["user"] }

          /// MyCaptainAssignment.EventVolunteer.User
          ///
          /// Parent Type: `User`
          struct User: AssemblyOpsAPI.SelectionSet {
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
              MyCaptainAssignmentsQuery.Data.MyCaptainAssignment.EventVolunteer.User.self
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