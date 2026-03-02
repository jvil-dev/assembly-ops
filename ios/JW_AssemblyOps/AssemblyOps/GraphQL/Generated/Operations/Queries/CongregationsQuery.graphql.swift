// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CongregationsQuery: GraphQLQuery {
    static let operationName: String = "Congregations"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Congregations($state: String!, $language: String) { congregations(state: $state, language: $language) { __typename id name state language circuit { __typename id code } } }"#
      ))

    public var state: String
    public var language: GraphQLNullable<String>

    public init(
      state: String,
      language: GraphQLNullable<String>
    ) {
      self.state = state
      self.language = language
    }

    public var __variables: Variables? { [
      "state": state,
      "language": language
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("congregations", [Congregation].self, arguments: [
          "state": .variable("state"),
          "language": .variable("language")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CongregationsQuery.Data.self
      ] }

      var congregations: [Congregation] { __data["congregations"] }

      /// Congregation
      ///
      /// Parent Type: `Congregation`
      struct Congregation: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Congregation }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("state", String.self),
          .field("language", String.self),
          .field("circuit", Circuit.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CongregationsQuery.Data.Congregation.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var state: String { __data["state"] }
        var language: String { __data["language"] }
        var circuit: Circuit { __data["circuit"] }

        /// Congregation.Circuit
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
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CongregationsQuery.Data.Congregation.Circuit.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var code: String { __data["code"] }
        }
      }
    }
  }

}