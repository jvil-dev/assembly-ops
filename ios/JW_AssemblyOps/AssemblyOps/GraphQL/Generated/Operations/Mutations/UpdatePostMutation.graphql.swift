// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class UpdatePostMutation: GraphQLMutation {
    static let operationName: String = "UpdatePost"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UpdatePost($id: ID!, $input: UpdatePostInput!) { updatePost(id: $id, input: $input) { __typename id name description location capacity category sortOrder createdAt } }"#
      ))

    public var id: ID
    public var input: UpdatePostInput

    public init(
      id: ID,
      input: UpdatePostInput
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
        .field("updatePost", UpdatePost.self, arguments: [
          "id": .variable("id"),
          "input": .variable("input")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UpdatePostMutation.Data.self
      ] }

      var updatePost: UpdatePost { __data["updatePost"] }

      /// UpdatePost
      ///
      /// Parent Type: `Post`
      struct UpdatePost: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Post }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("description", String?.self),
          .field("location", String?.self),
          .field("capacity", Int.self),
          .field("category", String?.self),
          .field("sortOrder", Int.self),
          .field("createdAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          UpdatePostMutation.Data.UpdatePost.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var description: String? { __data["description"] }
        var location: String? { __data["location"] }
        var capacity: Int { __data["capacity"] }
        var category: String? { __data["category"] }
        var sortOrder: Int { __data["sortOrder"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }
      }
    }
  }

}