// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class SearchVolunteerProfilesQuery: GraphQLQuery {
    static let operationName: String = "SearchVolunteerProfiles"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SearchVolunteerProfiles($query: String!, $circuitId: ID) { searchVolunteerProfiles(query: $query, circuitId: $circuitId) { __typename id firstName lastName email phone appointmentStatus congregation { __typename id name city } } }"#
      ))

    public var query: String
    public var circuitId: GraphQLNullable<ID>

    public init(
      query: String,
      circuitId: GraphQLNullable<ID>
    ) {
      self.query = query
      self.circuitId = circuitId
    }

    public var __variables: Variables? { [
      "query": query,
      "circuitId": circuitId
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("searchVolunteerProfiles", [SearchVolunteerProfile].self, arguments: [
          "query": .variable("query"),
          "circuitId": .variable("circuitId")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SearchVolunteerProfilesQuery.Data.self
      ] }

      var searchVolunteerProfiles: [SearchVolunteerProfile] { __data["searchVolunteerProfiles"] }

      /// SearchVolunteerProfile
      ///
      /// Parent Type: `VolunteerProfile`
      struct SearchVolunteerProfile: AssemblyOpsAPI.SelectionSet {
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
          SearchVolunteerProfilesQuery.Data.SearchVolunteerProfile.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var firstName: String { __data["firstName"] }
        var lastName: String { __data["lastName"] }
        var email: String? { __data["email"] }
        var phone: String? { __data["phone"] }
        var appointmentStatus: GraphQLEnum<AssemblyOpsAPI.AppointmentStatus>? { __data["appointmentStatus"] }
        var congregation: Congregation? { __data["congregation"] }

        /// SearchVolunteerProfile.Congregation
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
            SearchVolunteerProfilesQuery.Data.SearchVolunteerProfile.Congregation.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var city: String { __data["city"] }
        }
      }
    }
  }

}