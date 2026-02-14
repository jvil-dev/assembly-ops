// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CheckInStatsQuery: GraphQLQuery {
    static let operationName: String = "CheckInStats"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query CheckInStats($sessionId: ID!) { checkInStats(sessionId: $sessionId) { __typename sessionId totalAssignments checkedIn checkedOut noShow pending } }"#
      ))

    public var sessionId: ID

    public init(sessionId: ID) {
      self.sessionId = sessionId
    }

    public var __variables: Variables? { ["sessionId": sessionId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("checkInStats", CheckInStats.self, arguments: ["sessionId": .variable("sessionId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CheckInStatsQuery.Data.self
      ] }

      var checkInStats: CheckInStats { __data["checkInStats"] }

      /// CheckInStats
      ///
      /// Parent Type: `CheckInStats`
      struct CheckInStats: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.CheckInStats }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("sessionId", AssemblyOpsAPI.ID.self),
          .field("totalAssignments", Int.self),
          .field("checkedIn", Int.self),
          .field("checkedOut", Int.self),
          .field("noShow", Int.self),
          .field("pending", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CheckInStatsQuery.Data.CheckInStats.self
        ] }

        var sessionId: AssemblyOpsAPI.ID { __data["sessionId"] }
        var totalAssignments: Int { __data["totalAssignments"] }
        var checkedIn: Int { __data["checkedIn"] }
        var checkedOut: Int { __data["checkedOut"] }
        var noShow: Int { __data["noShow"] }
        var pending: Int { __data["pending"] }
      }
    }
  }

}