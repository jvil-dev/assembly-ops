// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CheckoutEquipmentMutation: GraphQLMutation {
    static let operationName: String = "CheckoutEquipment"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CheckoutEquipment($input: CheckoutEquipmentInput!) { checkoutEquipment(input: $input) { __typename id equipment { __typename id name category } checkedOutBy { __typename id user { __typename firstName lastName } } checkedOutAt session { __typename id name } notes } }"#
      ))

    public var input: CheckoutEquipmentInput

    public init(input: CheckoutEquipmentInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("checkoutEquipment", CheckoutEquipment.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CheckoutEquipmentMutation.Data.self
      ] }

      var checkoutEquipment: CheckoutEquipment { __data["checkoutEquipment"] }

      /// CheckoutEquipment
      ///
      /// Parent Type: `AVEquipmentCheckout`
      struct CheckoutEquipment: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVEquipmentCheckout }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("equipment", Equipment.self),
          .field("checkedOutBy", CheckedOutBy.self),
          .field("checkedOutAt", String.self),
          .field("session", Session?.self),
          .field("notes", String?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CheckoutEquipmentMutation.Data.CheckoutEquipment.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var equipment: Equipment { __data["equipment"] }
        var checkedOutBy: CheckedOutBy { __data["checkedOutBy"] }
        var checkedOutAt: String { __data["checkedOutAt"] }
        var session: Session? { __data["session"] }
        var notes: String? { __data["notes"] }

        /// CheckoutEquipment.Equipment
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
            .field("category", GraphQLEnum<AssemblyOpsAPI.AVEquipmentCategory>.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CheckoutEquipmentMutation.Data.CheckoutEquipment.Equipment.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var category: GraphQLEnum<AssemblyOpsAPI.AVEquipmentCategory> { __data["category"] }
        }

        /// CheckoutEquipment.CheckedOutBy
        ///
        /// Parent Type: `EventVolunteer`
        struct CheckedOutBy: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventVolunteer }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("user", User.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CheckoutEquipmentMutation.Data.CheckoutEquipment.CheckedOutBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var user: User { __data["user"] }

          /// CheckoutEquipment.CheckedOutBy.User
          ///
          /// Parent Type: `User`
          struct User: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.User }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("firstName", String.self),
              .field("lastName", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              CheckoutEquipmentMutation.Data.CheckoutEquipment.CheckedOutBy.User.self
            ] }

            var firstName: String { __data["firstName"] }
            var lastName: String { __data["lastName"] }
          }
        }

        /// CheckoutEquipment.Session
        ///
        /// Parent Type: `Session`
        struct Session: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Session }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CheckoutEquipmentMutation.Data.CheckoutEquipment.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}