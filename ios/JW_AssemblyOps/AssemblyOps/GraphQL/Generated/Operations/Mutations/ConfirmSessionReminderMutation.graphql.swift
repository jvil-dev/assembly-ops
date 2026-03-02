// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class ConfirmSessionReminderMutation: GraphQLMutation {
    static let operationName: String = "ConfirmSessionReminder"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation ConfirmSessionReminder($sessionId: ID!) { confirmSessionReminder(sessionId: $sessionId) { __typename id eventVolunteerId sessionId confirmedAt } }"#
      ))

    public var sessionId: ID

    public init(sessionId: ID) {
      self.sessionId = sessionId
    }

    public var __variables: Variables? { ["sessionId": sessionId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("confirmSessionReminder", ConfirmSessionReminder.self, arguments: ["sessionId": .variable("sessionId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ConfirmSessionReminderMutation.Data.self
      ] }

      var confirmSessionReminder: ConfirmSessionReminder { __data["confirmSessionReminder"] }

      /// ConfirmSessionReminder
      ///
      /// Parent Type: `ReminderConfirmation`
      struct ConfirmSessionReminder: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.ReminderConfirmation }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("eventVolunteerId", AssemblyOpsAPI.ID.self),
          .field("sessionId", AssemblyOpsAPI.ID?.self),
          .field("confirmedAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ConfirmSessionReminderMutation.Data.ConfirmSessionReminder.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var eventVolunteerId: AssemblyOpsAPI.ID { __data["eventVolunteerId"] }
        var sessionId: AssemblyOpsAPI.ID? { __data["sessionId"] }
        var confirmedAt: AssemblyOpsAPI.DateTime { __data["confirmedAt"] }
      }
    }
  }

}