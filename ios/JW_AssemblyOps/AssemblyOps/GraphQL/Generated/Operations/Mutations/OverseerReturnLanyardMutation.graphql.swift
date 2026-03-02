// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class OverseerReturnLanyardMutation: GraphQLMutation {
    static let operationName: String = "OverseerReturnLanyard"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation OverseerReturnLanyard($eventVolunteerId: ID!) { overseerReturnLanyard(eventVolunteerId: $eventVolunteerId) { __typename id eventVolunteerId date pickedUpAt returnedAt volunteerName } }"#
      ))

    public var eventVolunteerId: ID

    public init(eventVolunteerId: ID) {
      self.eventVolunteerId = eventVolunteerId
    }

    public var __variables: Variables? { ["eventVolunteerId": eventVolunteerId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("overseerReturnLanyard", OverseerReturnLanyard.self, arguments: ["eventVolunteerId": .variable("eventVolunteerId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        OverseerReturnLanyardMutation.Data.self
      ] }

      var overseerReturnLanyard: OverseerReturnLanyard { __data["overseerReturnLanyard"] }

      /// OverseerReturnLanyard
      ///
      /// Parent Type: `LanyardCheckout`
      struct OverseerReturnLanyard: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.LanyardCheckout }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("eventVolunteerId", AssemblyOpsAPI.ID.self),
          .field("date", String.self),
          .field("pickedUpAt", AssemblyOpsAPI.DateTime?.self),
          .field("returnedAt", AssemblyOpsAPI.DateTime?.self),
          .field("volunteerName", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          OverseerReturnLanyardMutation.Data.OverseerReturnLanyard.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var eventVolunteerId: AssemblyOpsAPI.ID { __data["eventVolunteerId"] }
        var date: String { __data["date"] }
        var pickedUpAt: AssemblyOpsAPI.DateTime? { __data["pickedUpAt"] }
        var returnedAt: AssemblyOpsAPI.DateTime? { __data["returnedAt"] }
        var volunteerName: String { __data["volunteerName"] }
      }
    }
  }

}