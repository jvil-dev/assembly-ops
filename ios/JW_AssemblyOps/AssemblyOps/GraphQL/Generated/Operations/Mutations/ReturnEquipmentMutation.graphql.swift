// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class ReturnEquipmentMutation: GraphQLMutation {
    static let operationName: String = "ReturnEquipment"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation ReturnEquipment($checkoutId: ID!) { returnEquipment(checkoutId: $checkoutId) { __typename id equipment { __typename id name } checkedInAt } }"#
      ))

    public var checkoutId: ID

    public init(checkoutId: ID) {
      self.checkoutId = checkoutId
    }

    public var __variables: Variables? { ["checkoutId": checkoutId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("returnEquipment", ReturnEquipment.self, arguments: ["checkoutId": .variable("checkoutId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ReturnEquipmentMutation.Data.self
      ] }

      var returnEquipment: ReturnEquipment { __data["returnEquipment"] }

      /// ReturnEquipment
      ///
      /// Parent Type: `AVEquipmentCheckout`
      struct ReturnEquipment: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVEquipmentCheckout }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("equipment", Equipment.self),
          .field("checkedInAt", String?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ReturnEquipmentMutation.Data.ReturnEquipment.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var equipment: Equipment { __data["equipment"] }
        var checkedInAt: String? { __data["checkedInAt"] }

        /// ReturnEquipment.Equipment
        ///
        /// Parent Type: `AVEquipmentItem`
        struct Equipment: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVEquipmentItem }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ReturnEquipmentMutation.Data.ReturnEquipment.Equipment.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}