// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CreateVolunteerProfileMutation: GraphQLMutation {
    static let operationName: String = "CreateVolunteerProfile"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CreateVolunteerProfile($input: CreateVolunteerProfileInput!) { createVolunteerProfile(input: $input) { __typename id firstName lastName email phone appointmentStatus congregation { __typename id name } } }"#
      ))

    public var input: CreateVolunteerProfileInput

    public init(input: CreateVolunteerProfileInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("createVolunteerProfile", CreateVolunteerProfile.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CreateVolunteerProfileMutation.Data.self
      ] }

      var createVolunteerProfile: CreateVolunteerProfile { __data["createVolunteerProfile"] }

      /// CreateVolunteerProfile
      ///
      /// Parent Type: `VolunteerProfile`
      struct CreateVolunteerProfile: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.VolunteerProfile }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("firstName", String.self),
          .field("lastName", String.self),
          .field("email", String?.self),
          .field("phone", String?.self),
          .field("appointmentStatus", GraphQLEnum<AssemblyOpsAPI.AppointmentStatus>.self),
          .field("congregation", Congregation.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CreateVolunteerProfileMutation.Data.CreateVolunteerProfile.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var firstName: String { __data["firstName"] }
        var lastName: String { __data["lastName"] }
        var email: String? { __data["email"] }
        var phone: String? { __data["phone"] }
        var appointmentStatus: GraphQLEnum<AssemblyOpsAPI.AppointmentStatus> { __data["appointmentStatus"] }
        var congregation: Congregation { __data["congregation"] }

        /// CreateVolunteerProfile.Congregation
        ///
        /// Parent Type: `Congregation`
        struct Congregation: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Congregation }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CreateVolunteerProfileMutation.Data.CreateVolunteerProfile.Congregation.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}