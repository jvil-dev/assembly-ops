// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class SearchCongregationsQuery: GraphQLQuery {
    static let operationName: String = "SearchCongregations"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SearchCongregations($query: String!) { searchCongregations(query: $query) { __typename id name state } }"#
      ))

    public var query: String

    public init(query: String) {
      self.query = query
    }

    public var __variables: Variables? { ["query": query] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("searchCongregations", [SearchCongregation].self, arguments: ["query": .variable("query")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SearchCongregationsQuery.Data.self
      ] }

      var searchCongregations: [SearchCongregation] { __data["searchCongregations"] }

      /// SearchCongregation
      ///
      /// Parent Type: `Congregation`
      struct SearchCongregation: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Congregation }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("state", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SearchCongregationsQuery.Data.SearchCongregation.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var state: String { __data["state"] }
      }
    }
  }

}