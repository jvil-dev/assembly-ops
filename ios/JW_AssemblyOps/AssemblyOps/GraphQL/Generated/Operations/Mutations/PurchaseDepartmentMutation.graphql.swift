// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class PurchaseDepartmentMutation: GraphQLMutation {
    static let operationName: String = "PurchaseDepartment"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation PurchaseDepartment($input: PurchaseDepartmentInput!) { purchaseDepartment(input: $input) { __typename id name departmentType accessCode isPublic } }"#
      ))

    public var input: PurchaseDepartmentInput

    public init(input: PurchaseDepartmentInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("purchaseDepartment", PurchaseDepartment.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        PurchaseDepartmentMutation.Data.self
      ] }

      var purchaseDepartment: PurchaseDepartment { __data["purchaseDepartment"] }

      /// PurchaseDepartment
      ///
      /// Parent Type: `Department`
      struct PurchaseDepartment: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Department }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("departmentType", GraphQLEnum<AssemblyOpsAPI.DepartmentType>.self),
          .field("accessCode", String?.self),
          .field("isPublic", Bool.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          PurchaseDepartmentMutation.Data.PurchaseDepartment.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType> { __data["departmentType"] }
        var accessCode: String? { __data["accessCode"] }
        var isPublic: Bool { __data["isPublic"] }
      }
    }
  }

}