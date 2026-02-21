// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CreatePostsMutation: GraphQLMutation {
    static let operationName: String = "CreatePosts"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CreatePosts($input: CreatePostsInput!) { createPosts(input: $input) { __typename id name description location capacity category sortOrder createdAt } }"#
      ))

    public var input: CreatePostsInput

    public init(input: CreatePostsInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("createPosts", [CreatePost].self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CreatePostsMutation.Data.self
      ] }

      var createPosts: [CreatePost] { __data["createPosts"] }

      /// CreatePost
      ///
      /// Parent Type: `Post`
      struct CreatePost: AssemblyOpsAPI.SelectionSet {
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
          CreatePostsMutation.Data.CreatePost.self
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