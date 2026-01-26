// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MyVolunteerProfileQuery: GraphQLQuery {
    static let operationName: String = "MyVolunteerProfile"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query MyVolunteerProfile { myVolunteerProfile { __typename id volunteerId firstName lastName fullName email phone congregation appointmentStatus event { __typename id name venue address startDate endDate } department { __typename id name departmentType } } }"#
      ))

    public init() {}

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("myVolunteerProfile", MyVolunteerProfile?.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MyVolunteerProfileQuery.Data.self
      ] }

      var myVolunteerProfile: MyVolunteerProfile? { __data["myVolunteerProfile"] }

      /// MyVolunteerProfile
      ///
      /// Parent Type: `Volunteer`
      struct MyVolunteerProfile: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Volunteer }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("volunteerId", String.self),
          .field("firstName", String.self),
          .field("lastName", String.self),
          .field("fullName", String.self),
          .field("email", String?.self),
          .field("phone", String?.self),
          .field("congregation", String.self),
          .field("appointmentStatus", GraphQLEnum<AssemblyOpsAPI.AppointmentStatus>?.self),
          .field("event", Event.self),
          .field("department", Department?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MyVolunteerProfileQuery.Data.MyVolunteerProfile.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var volunteerId: String { __data["volunteerId"] }
        var firstName: String { __data["firstName"] }
        var lastName: String { __data["lastName"] }
        var fullName: String { __data["fullName"] }
        var email: String? { __data["email"] }
        var phone: String? { __data["phone"] }
        var congregation: String { __data["congregation"] }
        var appointmentStatus: GraphQLEnum<AssemblyOpsAPI.AppointmentStatus>? { __data["appointmentStatus"] }
        var event: Event { __data["event"] }
        var department: Department? { __data["department"] }

        /// MyVolunteerProfile.Event
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
            .field("venue", String.self),
            .field("address", String.self),
            .field("startDate", AssemblyOpsAPI.DateTime.self),
            .field("endDate", AssemblyOpsAPI.DateTime.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MyVolunteerProfileQuery.Data.MyVolunteerProfile.Event.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var venue: String { __data["venue"] }
          var address: String { __data["address"] }
          var startDate: AssemblyOpsAPI.DateTime { __data["startDate"] }
          var endDate: AssemblyOpsAPI.DateTime { __data["endDate"] }
        }

        /// MyVolunteerProfile.Department
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
            MyVolunteerProfileQuery.Data.MyVolunteerProfile.Department.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType> { __data["departmentType"] }
        }
      }
    }
  }

}