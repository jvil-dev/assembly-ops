// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class AttendantPostsQuery: GraphQLQuery {
    static let operationName: String = "AttendantPosts"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query AttendantPosts($departmentId: ID!) { posts(departmentId: $departmentId) { __typename id name location category sortOrder } }"#
      ))

    public var departmentId: ID

    public init(departmentId: ID) {
      self.departmentId = departmentId
    }

    public var __variables: Variables? { ["departmentId": departmentId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("posts", [Post].self, arguments: ["departmentId": .variable("departmentId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AttendantPostsQuery.Data.self
      ] }

      var posts: [Post] { __data["posts"] }

      /// Post
      ///
      /// Parent Type: `Post`
      struct Post: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Post }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("location", String?.self),
          .field("category", String?.self),
          .field("sortOrder", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AttendantPostsQuery.Data.Post.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var location: String? { __data["location"] }
        var category: String? { __data["category"] }
        var sortOrder: Int { __data["sortOrder"] }
      }
    }
  }

}