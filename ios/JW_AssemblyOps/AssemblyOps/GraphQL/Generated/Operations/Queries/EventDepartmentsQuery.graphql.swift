// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class EventDepartmentsQuery: GraphQLQuery {
    static let operationName: String = "EventDepartments"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query EventDepartments($eventId: ID!) { eventDepartments(eventId: $eventId) { __typename id name departmentType volunteerCount } }"#
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
        .field("eventDepartments", [EventDepartment].self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        EventDepartmentsQuery.Data.self
      ] }

      var eventDepartments: [EventDepartment] { __data["eventDepartments"] }

      /// EventDepartment
      ///
      /// Parent Type: `Department`
      struct EventDepartment: AssemblyOpsAPI.SelectionSet {
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
          EventDepartmentsQuery.Data.EventDepartment.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType> { __data["departmentType"] }
        var volunteerCount: Int { __data["volunteerCount"] }
      }
    }
  }

}