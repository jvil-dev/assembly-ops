// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class LanyardStatusesQuery: GraphQLQuery {
    static let operationName: String = "LanyardStatuses"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query LanyardStatuses($eventId: ID!, $date: String) { lanyardStatuses(eventId: $eventId, date: $date) { __typename id eventVolunteerId eventId date pickedUpAt returnedAt volunteerName } }"#
      ))

    public var eventId: ID
    public var date: GraphQLNullable<String>

    public init(
      eventId: ID,
      date: GraphQLNullable<String>
    ) {
      self.eventId = eventId
      self.date = date
    }

    public var __variables: Variables? { [
      "eventId": eventId,
      "date": date
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("lanyardStatuses", [LanyardStatus].self, arguments: [
          "eventId": .variable("eventId"),
          "date": .variable("date")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        LanyardStatusesQuery.Data.self
      ] }

      var lanyardStatuses: [LanyardStatus] { __data["lanyardStatuses"] }

      /// LanyardStatus
      ///
      /// Parent Type: `LanyardCheckout`
      struct LanyardStatus: AssemblyOpsAPI.SelectionSet {
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
          LanyardStatusesQuery.Data.LanyardStatus.self
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