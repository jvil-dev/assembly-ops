// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class LoginVolunteerMutation: GraphQLMutation {
    static let operationName: String = "LoginVolunteer"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation LoginVolunteer($input: LoginEventVolunteerInput!) { loginEventVolunteer(input: $input) { __typename eventVolunteer { __typename id volunteerId user { __typename firstName lastName email phone appointmentStatus } event { __typename id name venue startDate endDate template { __typename theme } } department { __typename id name departmentType } } accessToken refreshToken expiresIn } }"#
      ))

    public var input: LoginEventVolunteerInput

    public init(input: LoginEventVolunteerInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("loginEventVolunteer", LoginEventVolunteer.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        LoginVolunteerMutation.Data.self
      ] }

      var loginEventVolunteer: LoginEventVolunteer { __data["loginEventVolunteer"] }

      /// LoginEventVolunteer
      ///
      /// Parent Type: `EventVolunteerAuthPayload`
      struct LoginEventVolunteer: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventVolunteerAuthPayload }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("eventVolunteer", EventVolunteer.self),
          .field("accessToken", String.self),
          .field("refreshToken", String.self),
          .field("expiresIn", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LoginVolunteerMutation.Data.LoginEventVolunteer.self
        ] }

        var eventVolunteer: EventVolunteer { __data["eventVolunteer"] }
        var accessToken: String { __data["accessToken"] }
        var refreshToken: String { __data["refreshToken"] }
        var expiresIn: Int { __data["expiresIn"] }

        /// LoginEventVolunteer.EventVolunteer
        ///
        /// Parent Type: `EventVolunteer`
        struct EventVolunteer: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventVolunteer }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("volunteerId", String.self),
            .field("user", User.self),
            .field("event", Event.self),
            .field("department", Department?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            LoginVolunteerMutation.Data.LoginEventVolunteer.EventVolunteer.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var volunteerId: String { __data["volunteerId"] }
          var user: User { __data["user"] }
          var event: Event { __data["event"] }
          var department: Department? { __data["department"] }

          /// LoginEventVolunteer.EventVolunteer.User
          ///
          /// Parent Type: `User`
          struct User: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.User }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("firstName", String.self),
              .field("lastName", String.self),
              .field("email", String.self),
              .field("phone", String?.self),
              .field("appointmentStatus", GraphQLEnum<AssemblyOpsAPI.AppointmentStatus>?.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              LoginVolunteerMutation.Data.LoginEventVolunteer.EventVolunteer.User.self
            ] }

            var firstName: String { __data["firstName"] }
            var lastName: String { __data["lastName"] }
            var email: String { __data["email"] }
            var phone: String? { __data["phone"] }
            var appointmentStatus: GraphQLEnum<AssemblyOpsAPI.AppointmentStatus>? { __data["appointmentStatus"] }
          }

          /// LoginEventVolunteer.EventVolunteer.Event
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
              .field("startDate", AssemblyOpsAPI.DateTime.self),
              .field("endDate", AssemblyOpsAPI.DateTime.self),
              .field("template", Template.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              LoginVolunteerMutation.Data.LoginEventVolunteer.EventVolunteer.Event.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
            var venue: String { __data["venue"] }
            var startDate: AssemblyOpsAPI.DateTime { __data["startDate"] }
            var endDate: AssemblyOpsAPI.DateTime { __data["endDate"] }
            var template: Template { __data["template"] }

            /// LoginEventVolunteer.EventVolunteer.Event.Template
            ///
            /// Parent Type: `EventTemplate`
            struct Template: AssemblyOpsAPI.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventTemplate }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("theme", String?.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                LoginVolunteerMutation.Data.LoginEventVolunteer.EventVolunteer.Event.Template.self
              ] }

              var theme: String? { __data["theme"] }
            }
          }

          /// LoginEventVolunteer.EventVolunteer.Department
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
              LoginVolunteerMutation.Data.LoginEventVolunteer.EventVolunteer.Department.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
            var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType> { __data["departmentType"] }
          }
        }
      }
    }
  }

}