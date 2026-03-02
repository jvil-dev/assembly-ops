// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MarkAllMessagesReadMutation: GraphQLMutation {
    static let operationName: String = "MarkAllMessagesRead"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation MarkAllMessagesRead($eventId: ID) { markAllMessagesRead(eventId: $eventId) { __typename markedCount } }"#
      ))

    public var eventId: GraphQLNullable<ID>

    public init(eventId: GraphQLNullable<ID>) {
      self.eventId = eventId
    }

    public var __variables: Variables? { ["eventId": eventId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("markAllMessagesRead", MarkAllMessagesRead.self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MarkAllMessagesReadMutation.Data.self
      ] }

      var markAllMessagesRead: MarkAllMessagesRead { __data["markAllMessagesRead"] }

      /// MarkAllMessagesRead
      ///
      /// Parent Type: `MarkAllReadResult`
      struct MarkAllMessagesRead: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.MarkAllReadResult }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("markedCount", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MarkAllMessagesReadMutation.Data.MarkAllMessagesRead.self
        ] }

        var markedCount: Int { __data["markedCount"] }
      }
    }
  }

}