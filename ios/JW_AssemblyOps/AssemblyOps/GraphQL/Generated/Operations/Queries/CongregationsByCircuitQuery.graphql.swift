// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CongregationsByCircuitQuery: GraphQLQuery {
    static let operationName: String = "CongregationsByCircuit"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query CongregationsByCircuit($circuitId: ID!) { congregationsByCircuit(circuitId: $circuitId) { __typename id name state language } }"#
      ))

    public var circuitId: ID

    public init(circuitId: ID) {
      self.circuitId = circuitId
    }

    public var __variables: Variables? { ["circuitId": circuitId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("congregationsByCircuit", [CongregationsByCircuit].self, arguments: ["circuitId": .variable("circuitId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CongregationsByCircuitQuery.Data.self
      ] }

      var congregationsByCircuit: [CongregationsByCircuit] { __data["congregationsByCircuit"] }

      /// CongregationsByCircuit
      ///
      /// Parent Type: `Congregation`
      struct CongregationsByCircuit: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Congregation }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("state", String.self),
          .field("language", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CongregationsByCircuitQuery.Data.CongregationsByCircuit.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var state: String { __data["state"] }
        var language: String { __data["language"] }
      }
    }
  }

}