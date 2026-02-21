// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class ResolveLostPersonAlertMutation: GraphQLMutation {
    static let operationName: String = "ResolveLostPersonAlert"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation ResolveLostPersonAlert($id: ID!, $resolutionNotes: String!) { resolveLostPersonAlert(id: $id, resolutionNotes: $resolutionNotes) { __typename id resolved resolvedAt resolutionNotes } }"#
      ))

    public var id: ID
    public var resolutionNotes: String

    public init(
      id: ID,
      resolutionNotes: String
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
        .field("resolveLostPersonAlert", ResolveLostPersonAlert.self, arguments: [
          "id": .variable("id"),
          "resolutionNotes": .variable("resolutionNotes")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ResolveLostPersonAlertMutation.Data.self
      ] }

      var resolveLostPersonAlert: ResolveLostPersonAlert { __data["resolveLostPersonAlert"] }

      /// ResolveLostPersonAlert
      ///
      /// Parent Type: `LostPersonAlert`
      struct ResolveLostPersonAlert: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.LostPersonAlert }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("resolved", Bool.self),
          .field("resolvedAt", String?.self),
          .field("resolutionNotes", String?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ResolveLostPersonAlertMutation.Data.ResolveLostPersonAlert.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var resolved: Bool { __data["resolved"] }
        var resolvedAt: String? { __data["resolvedAt"] }
        var resolutionNotes: String? { __data["resolutionNotes"] }
      }
    }
  }

}