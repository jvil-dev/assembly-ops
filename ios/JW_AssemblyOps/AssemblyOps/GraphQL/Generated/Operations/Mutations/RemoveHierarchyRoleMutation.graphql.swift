// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class RemoveHierarchyRoleMutation: GraphQLMutation {
    static let operationName: String = "RemoveHierarchyRole"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RemoveHierarchyRole($departmentId: ID!, $eventVolunteerId: ID!) { removeHierarchyRole( departmentId: $departmentId eventVolunteerId: $eventVolunteerId ) }"#
      ))

    public var departmentId: ID
    public var eventVolunteerId: ID

    public init(
      departmentId: ID,
      eventVolunteerId: ID
    ) {
      self.departmentId = departmentId
      self.eventVolunteerId = eventVolunteerId
    }

    public var __variables: Variables? { [
      "departmentId": departmentId,
      "eventVolunteerId": eventVolunteerId
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("removeHierarchyRole", Bool.self, arguments: [
          "departmentId": .variable("departmentId"),
          "eventVolunteerId": .variable("eventVolunteerId")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RemoveHierarchyRoleMutation.Data.self
      ] }

      var removeHierarchyRole: Bool { __data["removeHierarchyRole"] }
    }
  }

}