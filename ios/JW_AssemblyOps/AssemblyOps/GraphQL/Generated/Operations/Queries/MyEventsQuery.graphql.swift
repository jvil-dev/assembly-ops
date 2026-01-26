// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MyEventsQuery: GraphQLQuery {
    static let operationName: String = "MyEvents"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query MyEvents { myEvents { __typename id role claimedAt event { __typename id name eventType venue address startDate endDate volunteerCount } department { __typename id name departmentType volunteerCount } } }"#
      ))

    public init() {}

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("myEvents", [MyEvent].self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MyEventsQuery.Data.self
      ] }

      var myEvents: [MyEvent] { __data["myEvents"] }

      /// MyEvent
      ///
      /// Parent Type: `EventAdmin`
      struct MyEvent: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventAdmin }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("role", GraphQLEnum<AssemblyOpsAPI.EventRole>.self),
          .field("claimedAt", AssemblyOpsAPI.DateTime.self),
          .field("event", Event.self),
          .field("department", Department?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MyEventsQuery.Data.MyEvent.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var role: GraphQLEnum<AssemblyOpsAPI.EventRole> { __data["role"] }
        var claimedAt: AssemblyOpsAPI.DateTime { __data["claimedAt"] }
        var event: Event { __data["event"] }
        var department: Department? { __data["department"] }

        /// MyEvent.Event
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
            .field("volunteerCount", Int.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MyEventsQuery.Data.MyEvent.Event.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var eventType: GraphQLEnum<AssemblyOpsAPI.EventType> { __data["eventType"] }
          var venue: String { __data["venue"] }
          var address: String { __data["address"] }
          var startDate: AssemblyOpsAPI.DateTime { __data["startDate"] }
          var endDate: AssemblyOpsAPI.DateTime { __data["endDate"] }
          var volunteerCount: Int { __data["volunteerCount"] }
        }

        /// MyEvent.Department
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
            MyEventsQuery.Data.MyEvent.Department.self
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