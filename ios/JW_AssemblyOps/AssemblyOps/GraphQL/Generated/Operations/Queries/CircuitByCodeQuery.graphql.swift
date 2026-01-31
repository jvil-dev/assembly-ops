// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CircuitByCodeQuery: GraphQLQuery {
    static let operationName: String = "CircuitByCode"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query CircuitByCode($code: String!) { circuitByCode(code: $code) { __typename id code region language congregations { __typename id name city } } }"#
      ))

    public var code: String

    public init(code: String) {
      self.code = code
    }

    public var __variables: Variables? { ["code": code] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("circuitByCode", CircuitByCode?.self, arguments: ["code": .variable("code")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CircuitByCodeQuery.Data.self
      ] }

      var circuitByCode: CircuitByCode? { __data["circuitByCode"] }

      /// CircuitByCode
      ///
      /// Parent Type: `Circuit`
      struct CircuitByCode: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Circuit }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("code", String.self),
          .field("region", String.self),
          .field("language", String.self),
          .field("congregations", [Congregation?].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CircuitByCodeQuery.Data.CircuitByCode.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var code: String { __data["code"] }
        var region: String { __data["region"] }
        var language: String { __data["language"] }
        var congregations: [Congregation?] { __data["congregations"] }

        /// CircuitByCode.Congregation
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
            .field("city", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CircuitByCodeQuery.Data.CircuitByCode.Congregation.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var city: String { __data["city"] }
        }
      }
    }
  }

}