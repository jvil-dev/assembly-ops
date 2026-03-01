// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class BulkCreateAVEquipmentMutation: GraphQLMutation {
    static let operationName: String = "BulkCreateAVEquipment"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation BulkCreateAVEquipment($input: BulkCreateAVEquipmentInput!) { bulkCreateAVEquipment(input: $input) { __typename id name category condition location area { __typename id name } createdAt } }"#
      ))

    public var input: BulkCreateAVEquipmentInput

    public init(input: BulkCreateAVEquipmentInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("bulkCreateAVEquipment", [BulkCreateAVEquipment].self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        BulkCreateAVEquipmentMutation.Data.self
      ] }

      var bulkCreateAVEquipment: [BulkCreateAVEquipment] { __data["bulkCreateAVEquipment"] }

      /// BulkCreateAVEquipment
      ///
      /// Parent Type: `AVEquipmentItem`
      struct BulkCreateAVEquipment: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVEquipmentItem }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("category", GraphQLEnum<AssemblyOpsAPI.AVEquipmentCategory>.self),
          .field("condition", GraphQLEnum<AssemblyOpsAPI.AVEquipmentCondition>.self),
          .field("location", String?.self),
          .field("area", Area?.self),
          .field("createdAt", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          BulkCreateAVEquipmentMutation.Data.BulkCreateAVEquipment.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var category: GraphQLEnum<AssemblyOpsAPI.AVEquipmentCategory> { __data["category"] }
        var condition: GraphQLEnum<AssemblyOpsAPI.AVEquipmentCondition> { __data["condition"] }
        var location: String? { __data["location"] }
        var area: Area? { __data["area"] }
        var createdAt: String { __data["createdAt"] }

        /// BulkCreateAVEquipment.Area
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
            BulkCreateAVEquipmentMutation.Data.BulkCreateAVEquipment.Area.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}