// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class VolunteersQuery: GraphQLQuery {
    static let operationName: String = "Volunteers"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Volunteers($eventId: ID!, $departmentId: ID) { volunteers(eventId: $eventId, departmentId: $departmentId) { __typename id userId firstName lastName fullName email phone congregation appointmentStatus notes department { __typename id name departmentType } role { __typename id name } } }"#
      ))

    public var eventId: ID
    public var departmentId: GraphQLNullable<ID>

    public init(
      eventId: ID,
      departmentId: GraphQLNullable<ID>
    ) {
      self.eventId = eventId
      self.departmentId = departmentId
    }

    public var __variables: Variables? { [
      "eventId": eventId,
      "departmentId": departmentId
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("volunteers", [Volunteer].self, arguments: [
          "eventId": .variable("eventId"),
          "departmentId": .variable("departmentId")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        VolunteersQuery.Data.self
      ] }

      var volunteers: [Volunteer] { __data["volunteers"] }

      /// Volunteer
      ///
      /// Parent Type: `Volunteer`
      struct Volunteer: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Volunteer }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("userId", String.self),
          .field("firstName", String.self),
          .field("lastName", String.self),
          .field("fullName", String.self),
          .field("email", String?.self),
          .field("phone", String?.self),
          .field("congregation", String.self),
          .field("appointmentStatus", GraphQLEnum<AssemblyOpsAPI.AppointmentStatus>?.self),
          .field("notes", String?.self),
          .field("department", Department?.self),
          .field("role", Role?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          VolunteersQuery.Data.Volunteer.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var userId: String { __data["userId"] }
        var firstName: String { __data["firstName"] }
        var lastName: String { __data["lastName"] }
        var fullName: String { __data["fullName"] }
        var email: String? { __data["email"] }
        var phone: String? { __data["phone"] }
        var congregation: String { __data["congregation"] }
        var appointmentStatus: GraphQLEnum<AssemblyOpsAPI.AppointmentStatus>? { __data["appointmentStatus"] }
        var notes: String? { __data["notes"] }
        var department: Department? { __data["department"] }
        var role: Role? { __data["role"] }

        /// Volunteer.Department
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
            VolunteersQuery.Data.Volunteer.Department.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType> { __data["departmentType"] }
        }

        /// Volunteer.Role
        ///
        /// Parent Type: `Role`
        struct Role: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Role }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            VolunteersQuery.Data.Volunteer.Role.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}