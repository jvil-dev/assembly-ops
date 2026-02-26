// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class VolunteerProfilesQuery: GraphQLQuery {
    static let operationName: String = "VolunteerProfiles"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query VolunteerProfiles($congregationId: ID) { volunteerProfiles(congregationId: $congregationId) { __typename id firstName lastName email phone appointmentStatus congregation { __typename id name city } } }"#
      ))

    public var congregationId: GraphQLNullable<ID>

    public init(congregationId: GraphQLNullable<ID>) {
      self.congregationId = congregationId
    }

    public var __variables: Variables? { ["congregationId": congregationId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("volunteerProfiles", [VolunteerProfile].self, arguments: ["congregationId": .variable("congregationId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        VolunteerProfilesQuery.Data.self
      ] }

      var volunteerProfiles: [VolunteerProfile] { __data["volunteerProfiles"] }

      /// VolunteerProfile
      ///
      /// Parent Type: `VolunteerProfile`
      struct VolunteerProfile: AssemblyOpsAPI.SelectionSet {
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
          .field("appointmentStatus", GraphQLEnum<AssemblyOpsAPI.AppointmentStatus>?.self),
          .field("congregation", Congregation?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          VolunteerProfilesQuery.Data.VolunteerProfile.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var firstName: String { __data["firstName"] }
        var lastName: String { __data["lastName"] }
        var email: String? { __data["email"] }
        var phone: String? { __data["phone"] }
        var appointmentStatus: GraphQLEnum<AssemblyOpsAPI.AppointmentStatus>? { __data["appointmentStatus"] }
        var congregation: Congregation? { __data["congregation"] }

        /// VolunteerProfile.Congregation
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
            .field("city", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            VolunteerProfilesQuery.Data.VolunteerProfile.Congregation.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var city: String { __data["city"] }
        }
      }
    }
  }

}