// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class ResolveAVDamageMutation: GraphQLMutation {
    static let operationName: String = "ResolveAVDamage"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation ResolveAVDamage($id: ID!, $resolutionNotes: String) { resolveAVDamage(id: $id, resolutionNotes: $resolutionNotes) { __typename id resolved resolvedAt resolvedBy { __typename id firstName lastName } resolutionNotes } }"#
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
        .field("resolveAVDamage", ResolveAVDamage.self, arguments: [
          "id": .variable("id"),
          "resolutionNotes": .variable("resolutionNotes")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ResolveAVDamageMutation.Data.self
      ] }

      var resolveAVDamage: ResolveAVDamage { __data["resolveAVDamage"] }

      /// ResolveAVDamage
      ///
      /// Parent Type: `AVDamageReport`
      struct ResolveAVDamage: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVDamageReport }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("resolved", Bool.self),
          .field("resolvedAt", String?.self),
          .field("resolvedBy", ResolvedBy?.self),
          .field("resolutionNotes", String?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ResolveAVDamageMutation.Data.ResolveAVDamage.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var resolved: Bool { __data["resolved"] }
        var resolvedAt: String? { __data["resolvedAt"] }
        var resolvedBy: ResolvedBy? { __data["resolvedBy"] }
        var resolutionNotes: String? { __data["resolutionNotes"] }

        /// ResolveAVDamage.ResolvedBy
        ///
        /// Parent Type: `User`
        struct ResolvedBy: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.User }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("firstName", String.self),
            .field("lastName", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ResolveAVDamageMutation.Data.ResolveAVDamage.ResolvedBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }
      }
    }
  }

}