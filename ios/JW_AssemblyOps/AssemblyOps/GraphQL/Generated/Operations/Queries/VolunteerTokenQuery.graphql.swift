// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class VolunteerTokenQuery: GraphQLQuery {
    static let operationName: String = "VolunteerToken"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query VolunteerToken($id: ID!) { volunteerToken(id: $id) }"#
      ))

    public var id: ID

    public init(id: ID) {
      self.id = id
    }

    public var __variables: Variables? { ["id": id] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("volunteerToken", String.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        VolunteerTokenQuery.Data.self
      ] }

      var volunteerToken: String { __data["volunteerToken"] }
    }
  }

}