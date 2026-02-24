// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CreateFacilityLocationMutation: GraphQLMutation {
    static let operationName: String = "CreateFacilityLocation"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CreateFacilityLocation($input: CreateFacilityLocationInput!) { createFacilityLocation(input: $input) { __typename id name location description sortOrder } }"#
      ))

    public var input: CreateFacilityLocationInput

    public init(input: CreateFacilityLocationInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("createFacilityLocation", CreateFacilityLocation.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CreateFacilityLocationMutation.Data.self
      ] }

      var createFacilityLocation: CreateFacilityLocation { __data["createFacilityLocation"] }

      /// CreateFacilityLocation
      ///
      /// Parent Type: `FacilityLocation`
      struct CreateFacilityLocation: AssemblyOpsAPI.SelectionSet {
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
          CreateFacilityLocationMutation.Data.CreateFacilityLocation.self
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