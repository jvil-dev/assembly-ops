// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class SessionAssignmentCountsQuery: GraphQLQuery {
    static let operationName: String = "SessionAssignmentCounts"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SessionAssignmentCounts($sessionId: ID!) { sessionAssignments(sessionId: $sessionId) { __typename id volunteer { __typename id } } }"#
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
        .field("sessionAssignments", [SessionAssignment].self, arguments: ["sessionId": .variable("sessionId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SessionAssignmentCountsQuery.Data.self
      ] }

      var sessionAssignments: [SessionAssignment] { __data["sessionAssignments"] }

      /// SessionAssignment
      ///
      /// Parent Type: `ScheduleAssignment`
      struct SessionAssignment: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.ScheduleAssignment }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("volunteer", Volunteer?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SessionAssignmentCountsQuery.Data.SessionAssignment.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var volunteer: Volunteer? { __data["volunteer"] }

        /// SessionAssignment.Volunteer
        ///
        /// Parent Type: `Volunteer`
        struct Volunteer: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Volunteer }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SessionAssignmentCountsQuery.Data.SessionAssignment.Volunteer.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
        }
      }
    }
  }

}