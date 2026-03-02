// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CaptainDeleteAssignmentMutation: GraphQLMutation {
    static let operationName: String = "CaptainDeleteAssignment"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CaptainDeleteAssignment($eventId: ID!, $assignmentId: ID!) { captainDeleteAssignment(eventId: $eventId, assignmentId: $assignmentId) }"#
      ))

    public var eventId: ID
    public var assignmentId: ID

    public init(
      eventId: ID,
      assignmentId: ID
    ) {
      self.eventId = eventId
      self.assignmentId = assignmentId
    }

    public var __variables: Variables? { [
      "eventId": eventId,
      "assignmentId": assignmentId
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("captainDeleteAssignment", Bool.self, arguments: [
          "eventId": .variable("eventId"),
          "assignmentId": .variable("assignmentId")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CaptainDeleteAssignmentMutation.Data.self
      ] }

      var captainDeleteAssignment: Bool { __data["captainDeleteAssignment"] }
    }
  }

}