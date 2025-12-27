// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class LoginVolunteerMutation: GraphQLMutation {
    static let operationName: String = "LoginVolunteer"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation LoginVolunteer($input: LoginVolunteerInput!) { loginVolunteer(input: $input) { __typename volunteer { __typename id volunteerId firstName lastName fullName congregation event { __typename id name venue startDate endDate } department { __typename id name } } accessToken refreshToken expiresIn } }"#
      ))

    public var input: LoginVolunteerInput

    public init(input: LoginVolunteerInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("loginVolunteer", LoginVolunteer.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        LoginVolunteerMutation.Data.self
      ] }

      var loginVolunteer: LoginVolunteer { __data["loginVolunteer"] }

      /// LoginVolunteer
      ///
      /// Parent Type: `VolunteerAuthPayload`
      struct LoginVolunteer: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.VolunteerAuthPayload }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("volunteer", Volunteer.self),
          .field("accessToken", String.self),
          .field("refreshToken", String.self),
          .field("expiresIn", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LoginVolunteerMutation.Data.LoginVolunteer.self
        ] }

        var volunteer: Volunteer { __data["volunteer"] }
        var accessToken: String { __data["accessToken"] }
        var refreshToken: String { __data["refreshToken"] }
        var expiresIn: Int { __data["expiresIn"] }

        /// LoginVolunteer.Volunteer
        ///
        /// Parent Type: `Volunteer`
        struct Volunteer: AssemblyOpsAPI.SelectionSet {
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
            .field("congregation", String.self),
            .field("event", Event.self),
            .field("department", Department?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            LoginVolunteerMutation.Data.LoginVolunteer.Volunteer.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var volunteerId: String { __data["volunteerId"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
          var fullName: String { __data["fullName"] }
          var congregation: String { __data["congregation"] }
          var event: Event { __data["event"] }
          var department: Department? { __data["department"] }

          /// LoginVolunteer.Volunteer.Event
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
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              LoginVolunteerMutation.Data.LoginVolunteer.Volunteer.Event.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
            var venue: String { __data["venue"] }
            var startDate: AssemblyOpsAPI.DateTime { __data["startDate"] }
            var endDate: AssemblyOpsAPI.DateTime { __data["endDate"] }
          }

          /// LoginVolunteer.Volunteer.Department
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
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              LoginVolunteerMutation.Data.LoginVolunteer.Volunteer.Department.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
          }
        }
      }
    }
  }

}