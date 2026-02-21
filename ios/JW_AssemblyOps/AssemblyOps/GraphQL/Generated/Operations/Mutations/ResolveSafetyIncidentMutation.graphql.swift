// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class ResolveSafetyIncidentMutation: GraphQLMutation {
    static let operationName: String = "ResolveSafetyIncident"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation ResolveSafetyIncident($id: ID!, $resolutionNotes: String) { resolveSafetyIncident(id: $id, resolutionNotes: $resolutionNotes) { __typename id resolved resolvedAt resolutionNotes } }"#
      ))

    public var id: ID
    public var resolutionNotes: GraphQLNullable<String>

    public init(
      id: ID,
      resolutionNotes: GraphQLNullable<String>
    ) {
      self.id = id
      self.resolutionNotes = resolutionNotes
    }

    public var __variables: Variables? { [
      "id": id,
      "resolutionNotes": resolutionNotes
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("resolveSafetyIncident", ResolveSafetyIncident.self, arguments: [
          "id": .variable("id"),
          "resolutionNotes": .variable("resolutionNotes")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ResolveSafetyIncidentMutation.Data.self
      ] }

      var resolveSafetyIncident: ResolveSafetyIncident { __data["resolveSafetyIncident"] }

      /// ResolveSafetyIncident
      ///
      /// Parent Type: `SafetyIncident`
      struct ResolveSafetyIncident: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.SafetyIncident }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("resolved", Bool.self),
          .field("resolvedAt", String?.self),
          .field("resolutionNotes", String?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ResolveSafetyIncidentMutation.Data.ResolveSafetyIncident.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var resolved: Bool { __data["resolved"] }
        var resolvedAt: String? { __data["resolvedAt"] }
        var resolutionNotes: String? { __data["resolutionNotes"] }
      }
    }
  }

}