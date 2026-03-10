// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class UpsertDepartmentSessionMutation: GraphQLMutation {
    static let operationName: String = "UpsertDepartmentSession"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UpsertDepartmentSession($departmentId: ID!, $sessionId: ID!, $input: UpsertDepartmentSessionInput!) { upsertDepartmentSession( departmentId: $departmentId sessionId: $sessionId input: $input ) { __typename id departmentId sessionId startTime endTime notes } }"#
      ))

    public var departmentId: ID
    public var sessionId: ID
    public var input: UpsertDepartmentSessionInput

    public init(
      departmentId: ID,
      sessionId: ID,
      input: UpsertDepartmentSessionInput
    ) {
      self.departmentId = departmentId
      self.sessionId = sessionId
      self.input = input
    }

    public var __variables: Variables? { [
      "departmentId": departmentId,
      "sessionId": sessionId,
      "input": input
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("upsertDepartmentSession", UpsertDepartmentSession.self, arguments: [
          "departmentId": .variable("departmentId"),
          "sessionId": .variable("sessionId"),
          "input": .variable("input")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UpsertDepartmentSessionMutation.Data.self
      ] }

      var upsertDepartmentSession: UpsertDepartmentSession { __data["upsertDepartmentSession"] }

      /// UpsertDepartmentSession
      ///
      /// Parent Type: `DepartmentSession`
      struct UpsertDepartmentSession: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.DepartmentSession }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("departmentId", AssemblyOpsAPI.ID.self),
          .field("sessionId", AssemblyOpsAPI.ID.self),
          .field("startTime", AssemblyOpsAPI.DateTime?.self),
          .field("endTime", AssemblyOpsAPI.DateTime?.self),
          .field("notes", String?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          UpsertDepartmentSessionMutation.Data.UpsertDepartmentSession.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var departmentId: AssemblyOpsAPI.ID { __data["departmentId"] }
        var sessionId: AssemblyOpsAPI.ID { __data["sessionId"] }
        var startTime: AssemblyOpsAPI.DateTime? { __data["startTime"] }
        var endTime: AssemblyOpsAPI.DateTime? { __data["endTime"] }
        var notes: String? { __data["notes"] }
      }
    }
  }

}