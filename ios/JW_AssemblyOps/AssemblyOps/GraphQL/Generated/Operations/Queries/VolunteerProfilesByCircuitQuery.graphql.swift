// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class VolunteerProfilesByCircuitQuery: GraphQLQuery {
    static let operationName: String = "VolunteerProfilesByCircuit"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query VolunteerProfilesByCircuit($circuitId: ID!) { volunteerProfilesByCircuit(circuitId: $circuitId) { __typename id firstName lastName email phone appointmentStatus congregation { __typename id name } } }"#
      ))

    public var circuitId: ID

    public init(circuitId: ID) {
      self.circuitId = circuitId
    }

    public var __variables: Variables? { ["circuitId": circuitId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("volunteerProfilesByCircuit", [VolunteerProfilesByCircuit].self, arguments: ["circuitId": .variable("circuitId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        VolunteerProfilesByCircuitQuery.Data.self
      ] }

      var volunteerProfilesByCircuit: [VolunteerProfilesByCircuit] { __data["volunteerProfilesByCircuit"] }

      /// VolunteerProfilesByCircuit
      ///
      /// Parent Type: `VolunteerProfile`
      struct VolunteerProfilesByCircuit: AssemblyOpsAPI.SelectionSet {
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
          VolunteerProfilesByCircuitQuery.Data.VolunteerProfilesByCircuit.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var firstName: String { __data["firstName"] }
        var lastName: String { __data["lastName"] }
        var email: String? { __data["email"] }
        var phone: String? { __data["phone"] }
        var appointmentStatus: GraphQLEnum<AssemblyOpsAPI.AppointmentStatus>? { __data["appointmentStatus"] }
        var congregation: Congregation? { __data["congregation"] }

        /// VolunteerProfilesByCircuit.Congregation
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
            VolunteerProfilesByCircuitQuery.Data.VolunteerProfilesByCircuit.Congregation.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}