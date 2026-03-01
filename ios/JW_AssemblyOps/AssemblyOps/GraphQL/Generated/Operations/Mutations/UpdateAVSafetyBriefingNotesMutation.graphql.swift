// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class UpdateAVSafetyBriefingNotesMutation: GraphQLMutation {
    static let operationName: String = "UpdateAVSafetyBriefingNotes"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UpdateAVSafetyBriefingNotes($id: ID!, $notes: String!) { updateAVSafetyBriefingNotes(id: $id, notes: $notes) { __typename id topic notes } }"#
      ))

    public var id: ID
    public var notes: String

    public init(
      id: ID,
      notes: String
    ) {
      self.id = id
      self.notes = notes
    }

    public var __variables: Variables? { [
      "id": id,
      "notes": notes
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("updateAVSafetyBriefingNotes", UpdateAVSafetyBriefingNotes.self, arguments: [
          "id": .variable("id"),
          "notes": .variable("notes")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UpdateAVSafetyBriefingNotesMutation.Data.self
      ] }

      var updateAVSafetyBriefingNotes: UpdateAVSafetyBriefingNotes { __data["updateAVSafetyBriefingNotes"] }

      /// UpdateAVSafetyBriefingNotes
      ///
      /// Parent Type: `AVSafetyBriefing`
      struct UpdateAVSafetyBriefingNotes: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVSafetyBriefing }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("topic", String.self),
          .field("notes", String?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          UpdateAVSafetyBriefingNotesMutation.Data.UpdateAVSafetyBriefingNotes.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var topic: String { __data["topic"] }
        var notes: String? { __data["notes"] }
      }
    }
  }

}