// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class DeleteAVHazardAssessmentMutation: GraphQLMutation {
    static let operationName: String = "DeleteAVHazardAssessment"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation DeleteAVHazardAssessment($id: ID!) { deleteAVHazardAssessment(id: $id) }"#
      ))

    public var id: ID

    public init(id: ID) {
      self.id = id
    }

    public var __variables: Variables? { ["id": id] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("deleteAVHazardAssessment", Bool.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DeleteAVHazardAssessmentMutation.Data.self
      ] }

      var deleteAVHazardAssessment: Bool { __data["deleteAVHazardAssessment"] }
    }
  }

}