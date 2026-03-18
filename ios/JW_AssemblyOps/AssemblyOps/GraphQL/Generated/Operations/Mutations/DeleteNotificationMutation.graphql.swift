// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class DeleteNotificationMutation: GraphQLMutation {
    static let operationName: String = "DeleteNotification"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation DeleteNotification($notificationId: ID!) { deleteNotification(notificationId: $notificationId) }"#
      ))

    public var notificationId: ID

    public init(notificationId: ID) {
      self.notificationId = notificationId
    }

    public var __variables: Variables? { ["notificationId": notificationId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("deleteNotification", Bool.self, arguments: ["notificationId": .variable("notificationId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DeleteNotificationMutation.Data.self
      ] }

      var deleteNotification: Bool { __data["deleteNotification"] }
    }
  }

}