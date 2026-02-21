// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class ReportSafetyIncidentMutation: GraphQLMutation {
    static let operationName: String = "ReportSafetyIncident"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation ReportSafetyIncident($input: ReportSafetyIncidentInput!) { reportSafetyIncident(input: $input) { __typename id type description location post { __typename id name } createdAt } }"#
      ))

    public var input: ReportSafetyIncidentInput

    public init(input: ReportSafetyIncidentInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("reportSafetyIncident", ReportSafetyIncident.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ReportSafetyIncidentMutation.Data.self
      ] }

      var reportSafetyIncident: ReportSafetyIncident { __data["reportSafetyIncident"] }

      /// ReportSafetyIncident
      ///
      /// Parent Type: `SafetyIncident`
      struct ReportSafetyIncident: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.SafetyIncident }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("type", GraphQLEnum<AssemblyOpsAPI.SafetyIncidentType>.self),
          .field("description", String.self),
          .field("location", String?.self),
          .field("post", Post?.self),
          .field("createdAt", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ReportSafetyIncidentMutation.Data.ReportSafetyIncident.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var type: GraphQLEnum<AssemblyOpsAPI.SafetyIncidentType> { __data["type"] }
        var description: String { __data["description"] }
        var location: String? { __data["location"] }
        var post: Post? { __data["post"] }
        var createdAt: String { __data["createdAt"] }

        /// ReportSafetyIncident.Post
        ///
        /// Parent Type: `Post`
        struct Post: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Post }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ReportSafetyIncidentMutation.Data.ReportSafetyIncident.Post.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}