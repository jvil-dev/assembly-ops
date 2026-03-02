// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CreateAVEquipmentMutation: GraphQLMutation {
    static let operationName: String = "CreateAVEquipment"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CreateAVEquipment($input: CreateAVEquipmentInput!) { createAVEquipment(input: $input) { __typename id name model serialNumber category condition location notes area { __typename id name } createdAt } }"#
      ))

    public var input: CreateAVEquipmentInput

    public init(input: CreateAVEquipmentInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("createAVEquipment", CreateAVEquipment.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CreateAVEquipmentMutation.Data.self
      ] }

      var createAVEquipment: CreateAVEquipment { __data["createAVEquipment"] }

      /// CreateAVEquipment
      ///
      /// Parent Type: `AVEquipmentItem`
      struct CreateAVEquipment: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVEquipmentItem }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("model", String?.self),
          .field("serialNumber", String?.self),
          .field("category", GraphQLEnum<AssemblyOpsAPI.AVEquipmentCategory>.self),
          .field("condition", GraphQLEnum<AssemblyOpsAPI.AVEquipmentCondition>.self),
          .field("location", String?.self),
          .field("notes", String?.self),
          .field("area", Area?.self),
          .field("createdAt", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CreateAVEquipmentMutation.Data.CreateAVEquipment.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var model: String? { __data["model"] }
        var serialNumber: String? { __data["serialNumber"] }
        var category: GraphQLEnum<AssemblyOpsAPI.AVEquipmentCategory> { __data["category"] }
        var condition: GraphQLEnum<AssemblyOpsAPI.AVEquipmentCondition> { __data["condition"] }
        var location: String? { __data["location"] }
        var notes: String? { __data["notes"] }
        var area: Area? { __data["area"] }
        var createdAt: String { __data["createdAt"] }

        /// CreateAVEquipment.Area
        ///
        /// Parent Type: `Area`
        struct Area: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Area }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CreateAVEquipmentMutation.Data.CreateAVEquipment.Area.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}