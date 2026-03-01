// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MyAllEventsQuery: GraphQLQuery {
    static let operationName: String = "MyAllEvents"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query MyAllEvents { myAllEvents { __typename eventId membershipType overseerRole departmentId departmentName departmentType eventVolunteerId departmentAccessCode event { __typename id name eventType theme venue address startDate endDate volunteerCount } } }"#
      ))

    public init() {}

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("myAllEvents", [MyAllEvent].self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MyAllEventsQuery.Data.self
      ] }

      var myAllEvents: [MyAllEvent] { __data["myAllEvents"] }

      /// MyAllEvent
      ///
      /// Parent Type: `UserEventMembership`
      struct MyAllEvent: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.UserEventMembership }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("eventId", AssemblyOpsAPI.ID.self),
          .field("membershipType", GraphQLEnum<AssemblyOpsAPI.UserEventMembershipType>.self),
          .field("overseerRole", GraphQLEnum<AssemblyOpsAPI.EventRole>?.self),
          .field("departmentId", AssemblyOpsAPI.ID?.self),
          .field("departmentName", String?.self),
          .field("departmentType", GraphQLEnum<AssemblyOpsAPI.DepartmentType>?.self),
          .field("eventVolunteerId", AssemblyOpsAPI.ID?.self),
          .field("departmentAccessCode", String?.self),
          .field("event", Event.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MyAllEventsQuery.Data.MyAllEvent.self
        ] }

        var eventId: AssemblyOpsAPI.ID { __data["eventId"] }
        var membershipType: GraphQLEnum<AssemblyOpsAPI.UserEventMembershipType> { __data["membershipType"] }
        var overseerRole: GraphQLEnum<AssemblyOpsAPI.EventRole>? { __data["overseerRole"] }
        var departmentId: AssemblyOpsAPI.ID? { __data["departmentId"] }
        var departmentName: String? { __data["departmentName"] }
        var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType>? { __data["departmentType"] }
        var eventVolunteerId: AssemblyOpsAPI.ID? { __data["eventVolunteerId"] }
        var departmentAccessCode: String? { __data["departmentAccessCode"] }
        var event: Event { __data["event"] }

        /// MyAllEvent.Event
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
            .field("theme", String?.self),
            .field("venue", String.self),
            .field("address", String.self),
            .field("startDate", AssemblyOpsAPI.DateTime.self),
            .field("endDate", AssemblyOpsAPI.DateTime.self),
            .field("volunteerCount", Int.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MyAllEventsQuery.Data.MyAllEvent.Event.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var eventType: GraphQLEnum<AssemblyOpsAPI.EventType> { __data["eventType"] }
          var theme: String? { __data["theme"] }
          var venue: String { __data["venue"] }
          var address: String { __data["address"] }
          var startDate: AssemblyOpsAPI.DateTime { __data["startDate"] }
          var endDate: AssemblyOpsAPI.DateTime { __data["endDate"] }
          var volunteerCount: Int { __data["volunteerCount"] }
        }
      }
    }
  }

}