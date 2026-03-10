// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class UpdateAreaMutation: GraphQLMutation {
    static let operationName: String = "UpdateArea"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UpdateArea($id: ID!, $input: UpdateAreaInput!) { updateArea(id: $id, input: $input) { __typename id name description category sortOrder startTime endTime postCount } }"#
      ))

    public var id: ID
    public var input: UpdateAreaInput

    public init(
      id: ID,
      input: UpdateAreaInput
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
        .field("updateArea", UpdateArea.self, arguments: [
          "id": .variable("id"),
          "input": .variable("input")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UpdateAreaMutation.Data.self
      ] }

      var updateArea: UpdateArea { __data["updateArea"] }

      /// UpdateArea
      ///
      /// Parent Type: `Area`
      struct UpdateArea: AssemblyOpsAPI.SelectionSet {
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
          .field("startTime", String?.self),
          .field("endTime", String?.self),
          .field("postCount", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          UpdateAreaMutation.Data.UpdateArea.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var description: String? { __data["description"] }
        var category: String? { __data["category"] }
        var sortOrder: Int { __data["sortOrder"] }
        var startTime: String? { __data["startTime"] }
        var endTime: String? { __data["endTime"] }
        var postCount: Int { __data["postCount"] }
      }
    }
  }

}