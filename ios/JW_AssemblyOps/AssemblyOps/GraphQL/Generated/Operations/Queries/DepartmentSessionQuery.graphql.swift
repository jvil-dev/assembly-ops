// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class DepartmentSessionQuery: GraphQLQuery {
    static let operationName: String = "DepartmentSession"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query DepartmentSession($sessionId: ID!, $departmentId: ID!) { session(id: $sessionId) { __typename id departmentSession(departmentId: $departmentId) { __typename id departmentId sessionId startTime endTime notes } } }"#
      ))

    public var sessionId: ID
    public var departmentId: ID

    public init(
      sessionId: ID,
      departmentId: ID
    ) {
      self.sessionId = sessionId
      self.departmentId = departmentId
    }

    public var __variables: Variables? { [
      "sessionId": sessionId,
      "departmentId": departmentId
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("session", Session?.self, arguments: ["id": .variable("sessionId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DepartmentSessionQuery.Data.self
      ] }

      var session: Session? { __data["session"] }

      /// Session
      ///
      /// Parent Type: `Session`
      struct Session: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Session }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("departmentSession", DepartmentSession?.self, arguments: ["departmentId": .variable("departmentId")]),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          DepartmentSessionQuery.Data.Session.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var departmentSession: DepartmentSession? { __data["departmentSession"] }

        /// Session.DepartmentSession
        ///
        /// Parent Type: `DepartmentSession`
        struct DepartmentSession: AssemblyOpsAPI.SelectionSet {
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
            DepartmentSessionQuery.Data.Session.DepartmentSession.self
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

}