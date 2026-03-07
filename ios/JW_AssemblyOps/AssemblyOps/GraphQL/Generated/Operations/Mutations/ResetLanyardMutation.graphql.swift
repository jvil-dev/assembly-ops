// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class ResetLanyardMutation: GraphQLMutation {
    static let operationName: String = "ResetLanyard"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation ResetLanyard($eventId: ID!) { resetLanyard(eventId: $eventId) { __typename id eventVolunteerId eventId date pickedUpAt returnedAt volunteerName } }"#
      ))

    public var eventId: ID

    public init(eventId: ID) {
      self.eventId = eventId
    }

    public var __variables: Variables? { ["eventId": eventId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("resetLanyard", ResetLanyard.self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ResetLanyardMutation.Data.self
      ] }

      var resetLanyard: ResetLanyard { __data["resetLanyard"] }

      /// ResetLanyard
      ///
      /// Parent Type: `LanyardCheckout`
      struct ResetLanyard: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.LanyardCheckout }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("eventVolunteerId", AssemblyOpsAPI.ID.self),
          .field("eventId", AssemblyOpsAPI.ID.self),
          .field("date", String.self),
          .field("pickedUpAt", AssemblyOpsAPI.DateTime?.self),
          .field("returnedAt", AssemblyOpsAPI.DateTime?.self),
          .field("volunteerName", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ResetLanyardMutation.Data.ResetLanyard.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var eventVolunteerId: AssemblyOpsAPI.ID { __data["eventVolunteerId"] }
        var eventId: AssemblyOpsAPI.ID { __data["eventId"] }
        var date: String { __data["date"] }
        var pickedUpAt: AssemblyOpsAPI.DateTime? { __data["pickedUpAt"] }
        var returnedAt: AssemblyOpsAPI.DateTime? { __data["returnedAt"] }
        var volunteerName: String { __data["volunteerName"] }
      }
    }
  }

}