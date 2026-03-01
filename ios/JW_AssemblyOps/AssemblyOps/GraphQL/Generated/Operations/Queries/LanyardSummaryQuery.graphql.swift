// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class LanyardSummaryQuery: GraphQLQuery {
    static let operationName: String = "LanyardSummary"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query LanyardSummary($eventId: ID!, $date: String) { lanyardSummary(eventId: $eventId, date: $date) { __typename total pickedUp returned notPickedUp } }"#
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
        .field("lanyardSummary", LanyardSummary.self, arguments: [
          "eventId": .variable("eventId"),
          "date": .variable("date")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        LanyardSummaryQuery.Data.self
      ] }

      var lanyardSummary: LanyardSummary { __data["lanyardSummary"] }

      /// LanyardSummary
      ///
      /// Parent Type: `LanyardSummary`
      struct LanyardSummary: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.LanyardSummary }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("total", Int.self),
          .field("pickedUp", Int.self),
          .field("returned", Int.self),
          .field("notPickedUp", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LanyardSummaryQuery.Data.LanyardSummary.self
        ] }

        var total: Int { __data["total"] }
        var pickedUp: Int { __data["pickedUp"] }
        var returned: Int { __data["returned"] }
        var notPickedUp: Int { __data["notPickedUp"] }
      }
    }
  }

}