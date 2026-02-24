// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CreateAreaMutation: GraphQLMutation {
    static let operationName: String = "CreateArea"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CreateArea($departmentId: ID!, $input: CreateAreaInput!) { createArea(departmentId: $departmentId, input: $input) { __typename id name description category sortOrder postCount } }"#
      ))

    public var departmentId: ID
    public var input: CreateAreaInput

    public init(
      departmentId: ID,
      input: CreateAreaInput
    ) {
      self.departmentId = departmentId
      self.input = input
    }

    public var __variables: Variables? { [
      "departmentId": departmentId,
      "input": input
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("createArea", CreateArea.self, arguments: [
          "departmentId": .variable("departmentId"),
          "input": .variable("input")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CreateAreaMutation.Data.self
      ] }

      var createArea: CreateArea { __data["createArea"] }

      /// CreateArea
      ///
      /// Parent Type: `Area`
      struct CreateArea: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Area }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("description", String?.self),
          .field("category", String?.self),
          .field("sortOrder", Int.self),
          .field("postCount", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CreateAreaMutation.Data.CreateArea.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var description: String? { __data["description"] }
        var category: String? { __data["category"] }
        var sortOrder: Int { __data["sortOrder"] }
        var postCount: Int { __data["postCount"] }
      }
    }
  }

}