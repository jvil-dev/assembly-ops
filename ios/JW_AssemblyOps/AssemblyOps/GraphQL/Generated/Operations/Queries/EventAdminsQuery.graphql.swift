// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class EventAdminsQuery: GraphQLQuery {
    static let operationName: String = "EventAdmins"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query EventAdmins($eventId: ID!) { eventAdmins(eventId: $eventId) { __typename id role claimedAt admin { __typename id firstName lastName email } department { __typename id name departmentType } } }"#
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
        .field("eventAdmins", [EventAdmin].self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        EventAdminsQuery.Data.self
      ] }

      var eventAdmins: [EventAdmin] { __data["eventAdmins"] }

      /// EventAdmin
      ///
      /// Parent Type: `EventAdmin`
      struct EventAdmin: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventAdmin }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("role", GraphQLEnum<AssemblyOpsAPI.EventRole>.self),
          .field("claimedAt", AssemblyOpsAPI.DateTime.self),
          .field("admin", Admin.self),
          .field("department", Department?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          EventAdminsQuery.Data.EventAdmin.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var role: GraphQLEnum<AssemblyOpsAPI.EventRole> { __data["role"] }
        var claimedAt: AssemblyOpsAPI.DateTime { __data["claimedAt"] }
        var admin: Admin { __data["admin"] }
        var department: Department? { __data["department"] }

        /// EventAdmin.Admin
        ///
        /// Parent Type: `Admin`
        struct Admin: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Admin }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("firstName", String.self),
            .field("lastName", String.self),
            .field("email", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            EventAdminsQuery.Data.EventAdmin.Admin.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
          var email: String { __data["email"] }
        }

        /// EventAdmin.Department
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
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            EventAdminsQuery.Data.EventAdmin.Department.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType> { __data["departmentType"] }
        }
      }
    }
  }

}