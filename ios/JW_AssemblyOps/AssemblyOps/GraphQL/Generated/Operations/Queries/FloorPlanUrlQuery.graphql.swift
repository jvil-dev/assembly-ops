// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class FloorPlanUrlQuery: GraphQLQuery {
    static let operationName: String = "FloorPlanUrl"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query FloorPlanUrl($eventId: ID!) { floorPlanUrl(eventId: $eventId) }"#
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
        .field("floorPlanUrl", String?.self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        FloorPlanUrlQuery.Data.self
      ] }

      var floorPlanUrl: String? { __data["floorPlanUrl"] }
    }
  }

}