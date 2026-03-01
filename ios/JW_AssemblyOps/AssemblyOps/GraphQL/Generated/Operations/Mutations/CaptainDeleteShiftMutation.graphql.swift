// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CaptainDeleteShiftMutation: GraphQLMutation {
    static let operationName: String = "CaptainDeleteShift"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CaptainDeleteShift($id: ID!, $eventId: ID!) { captainDeleteShift(id: $id, eventId: $eventId) }"#
      ))

    public var id: ID
    public var eventId: ID

    public init(
      id: ID,
      eventId: ID
    ) {
      self.id = id
      self.eventId = eventId
    }

    public var __variables: Variables? { [
      "id": id,
      "eventId": eventId
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("captainDeleteShift", Bool.self, arguments: [
          "id": .variable("id"),
          "eventId": .variable("eventId")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CaptainDeleteShiftMutation.Data.self
      ] }

      var captainDeleteShift: Bool { __data["captainDeleteShift"] }
    }
  }

}