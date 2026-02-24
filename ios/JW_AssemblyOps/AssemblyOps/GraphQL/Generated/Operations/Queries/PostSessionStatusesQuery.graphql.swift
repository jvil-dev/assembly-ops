// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class PostSessionStatusesQuery: GraphQLQuery {
    static let operationName: String = "PostSessionStatuses"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query PostSessionStatuses($sessionId: ID!) { postSessionStatuses(sessionId: $sessionId) { __typename id post { __typename id name location category } session { __typename id name } status updatedAt } }"#
      ))

    public var sessionId: ID

    public init(sessionId: ID) {
      self.sessionId = sessionId
    }

    public var __variables: Variables? { ["sessionId": sessionId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("postSessionStatuses", [PostSessionStatus].self, arguments: ["sessionId": .variable("sessionId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        PostSessionStatusesQuery.Data.self
      ] }

      var postSessionStatuses: [PostSessionStatus] { __data["postSessionStatuses"] }

      /// PostSessionStatus
      ///
      /// Parent Type: `PostSessionStatus`
      struct PostSessionStatus: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.PostSessionStatus }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("post", Post.self),
          .field("session", Session.self),
          .field("status", GraphQLEnum<AssemblyOpsAPI.SeatingSectionStatus>.self),
          .field("updatedAt", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          PostSessionStatusesQuery.Data.PostSessionStatus.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var post: Post { __data["post"] }
        var session: Session { __data["session"] }
        var status: GraphQLEnum<AssemblyOpsAPI.SeatingSectionStatus> { __data["status"] }
        var updatedAt: String { __data["updatedAt"] }

        /// PostSessionStatus.Post
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
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            PostSessionStatusesQuery.Data.PostSessionStatus.Post.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var location: String? { __data["location"] }
          var category: String? { __data["category"] }
        }

        /// PostSessionStatus.Session
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
            PostSessionStatusesQuery.Data.PostSessionStatus.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}