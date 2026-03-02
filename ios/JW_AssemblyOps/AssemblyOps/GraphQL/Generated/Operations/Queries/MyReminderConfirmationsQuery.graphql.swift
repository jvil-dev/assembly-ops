// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MyReminderConfirmationsQuery: GraphQLQuery {
    static let operationName: String = "MyReminderConfirmations"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query MyReminderConfirmations($eventId: ID!) { myReminderConfirmations(eventId: $eventId) { __typename id eventVolunteerId shiftId sessionId confirmedAt } }"#
      ))

    public var eventId: ID

    public init(eventId: ID) {
      self.eventId = eventId
    }

    public var __variables: Variables? { ["eventId": eventId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("myReminderConfirmations", [MyReminderConfirmation].self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MyReminderConfirmationsQuery.Data.self
      ] }

      var myReminderConfirmations: [MyReminderConfirmation] { __data["myReminderConfirmations"] }

      /// MyReminderConfirmation
      ///
      /// Parent Type: `ReminderConfirmation`
      struct MyReminderConfirmation: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.ReminderConfirmation }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("eventVolunteerId", AssemblyOpsAPI.ID.self),
          .field("shiftId", AssemblyOpsAPI.ID?.self),
          .field("sessionId", AssemblyOpsAPI.ID?.self),
          .field("confirmedAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MyReminderConfirmationsQuery.Data.MyReminderConfirmation.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var eventVolunteerId: AssemblyOpsAPI.ID { __data["eventVolunteerId"] }
        var shiftId: AssemblyOpsAPI.ID? { __data["shiftId"] }
        var sessionId: AssemblyOpsAPI.ID? { __data["sessionId"] }
        var confirmedAt: AssemblyOpsAPI.DateTime { __data["confirmedAt"] }
      }
    }
  }

}