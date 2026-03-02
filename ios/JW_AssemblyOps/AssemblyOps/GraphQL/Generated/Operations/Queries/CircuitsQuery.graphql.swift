// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CircuitsQuery: GraphQLQuery {
    static let operationName: String = "Circuits"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Circuits($region: String, $language: String) { circuits(region: $region, language: $language) { __typename id code region language } }"#
      ))

    public var region: GraphQLNullable<String>
    public var language: GraphQLNullable<String>

    public init(
      region: GraphQLNullable<String>,
      language: GraphQLNullable<String>
    ) {
      self.region = region
      self.language = language
    }

    public var __variables: Variables? { [
      "region": region,
      "language": language
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("circuits", [Circuit].self, arguments: [
          "region": .variable("region"),
          "language": .variable("language")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CircuitsQuery.Data.self
      ] }

      var circuits: [Circuit] { __data["circuits"] }

      /// Circuit
      ///
      /// Parent Type: `Circuit`
      struct Circuit: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Circuit }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("code", String.self),
          .field("region", String.self),
          .field("language", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CircuitsQuery.Data.Circuit.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var code: String { __data["code"] }
        var region: String { __data["region"] }
        var language: String { __data["language"] }
      }
    }
  }

}