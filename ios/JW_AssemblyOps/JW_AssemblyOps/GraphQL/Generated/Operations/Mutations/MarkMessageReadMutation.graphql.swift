// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MarkMessageReadMutation: GraphQLMutation {
    static let operationName: String = "MarkMessageRead"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation MarkMessageRead($id: ID!) { markMessageRead(id: $id) { __typename id isRead readAt } }"#
      ))

    public var id: ID

    public init(id: ID) {
      self.id = id
    }

    public var __variables: Variables? { ["id": id] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("markMessageRead", MarkMessageRead.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MarkMessageReadMutation.Data.self
      ] }

      var markMessageRead: MarkMessageRead { __data["markMessageRead"] }

      /// MarkMessageRead
      ///
      /// Parent Type: `Message`
      struct MarkMessageRead: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Message }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("isRead", Bool.self),
          .field("readAt", AssemblyOpsAPI.DateTime?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MarkMessageReadMutation.Data.MarkMessageRead.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var isRead: Bool { __data["isRead"] }
        var readAt: AssemblyOpsAPI.DateTime? { __data["readAt"] }
      }
    }
  }

}