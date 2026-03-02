// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class UpdateFacilityLocationMutation: GraphQLMutation {
    static let operationName: String = "UpdateFacilityLocation"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UpdateFacilityLocation($id: ID!, $input: UpdateFacilityLocationInput!) { updateFacilityLocation(id: $id, input: $input) { __typename id name location description sortOrder } }"#
      ))

    public var id: ID
    public var input: UpdateFacilityLocationInput

    public init(
      id: ID,
      input: UpdateFacilityLocationInput
    ) {
      self.id = id
      self.input = input
    }

    public var __variables: Variables? { [
      "id": id,
      "input": input
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("updateFacilityLocation", UpdateFacilityLocation.self, arguments: [
          "id": .variable("id"),
          "input": .variable("input")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UpdateFacilityLocationMutation.Data.self
      ] }

      var updateFacilityLocation: UpdateFacilityLocation { __data["updateFacilityLocation"] }

      /// UpdateFacilityLocation
      ///
      /// Parent Type: `FacilityLocation`
      struct UpdateFacilityLocation: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.FacilityLocation }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("location", String.self),
          .field("description", String?.self),
          .field("sortOrder", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          UpdateFacilityLocationMutation.Data.UpdateFacilityLocation.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var location: String { __data["location"] }
        var description: String? { __data["description"] }
        var sortOrder: Int { __data["sortOrder"] }
      }
    }
  }

}