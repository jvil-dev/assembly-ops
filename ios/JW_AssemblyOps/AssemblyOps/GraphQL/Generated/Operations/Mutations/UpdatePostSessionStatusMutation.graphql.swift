// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class UpdatePostSessionStatusMutation: GraphQLMutation {
    static let operationName: String = "UpdatePostSessionStatus"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UpdatePostSessionStatus($input: UpdatePostSessionStatusInput!) { updatePostSessionStatus(input: $input) { __typename id post { __typename id name } session { __typename id name } status updatedAt } }"#
      ))

    public var input: UpdatePostSessionStatusInput

    public init(input: UpdatePostSessionStatusInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("updatePostSessionStatus", UpdatePostSessionStatus.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UpdatePostSessionStatusMutation.Data.self
      ] }

      var updatePostSessionStatus: UpdatePostSessionStatus { __data["updatePostSessionStatus"] }

      /// UpdatePostSessionStatus
      ///
      /// Parent Type: `PostSessionStatus`
      struct UpdatePostSessionStatus: AssemblyOpsAPI.SelectionSet {
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
          UpdatePostSessionStatusMutation.Data.UpdatePostSessionStatus.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var post: Post { __data["post"] }
        var session: Session { __data["session"] }
        var status: GraphQLEnum<AssemblyOpsAPI.SeatingSectionStatus> { __data["status"] }
        var updatedAt: String { __data["updatedAt"] }

        /// UpdatePostSessionStatus.Post
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
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            UpdatePostSessionStatusMutation.Data.UpdatePostSessionStatus.Post.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// UpdatePostSessionStatus.Session
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
            UpdatePostSessionStatusMutation.Data.UpdatePostSessionStatus.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}