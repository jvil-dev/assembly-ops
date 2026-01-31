// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class ClaimDepartmentMutation: GraphQLMutation {
    static let operationName: String = "ClaimDepartment"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation ClaimDepartment($input: ClaimDepartmentInput!) { claimDepartment(input: $input) { __typename id name departmentType } }"#
      ))

    public var input: ClaimDepartmentInput

    public init(input: ClaimDepartmentInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("claimDepartment", ClaimDepartment.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ClaimDepartmentMutation.Data.self
      ] }

      var claimDepartment: ClaimDepartment { __data["claimDepartment"] }

      /// ClaimDepartment
      ///
      /// Parent Type: `Department`
      struct ClaimDepartment: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Department }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("departmentType", GraphQLEnum<AssemblyOpsAPI.DepartmentType>.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ClaimDepartmentMutation.Data.ClaimDepartment.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType> { __data["departmentType"] }
      }
    }
  }

}