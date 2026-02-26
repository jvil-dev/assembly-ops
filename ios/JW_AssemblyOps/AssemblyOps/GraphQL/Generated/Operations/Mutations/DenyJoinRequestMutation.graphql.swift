// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class DenyJoinRequestMutation: GraphQLMutation {
    static let operationName: String = "DenyJoinRequest"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation DenyJoinRequest($requestId: ID!, $reason: String) { denyJoinRequest(requestId: $requestId, reason: $reason) { __typename id eventId user { __typename id firstName lastName } departmentType status note createdAt resolvedAt } }"#
      ))

    public var requestId: ID
    public var reason: GraphQLNullable<String>

    public init(
      requestId: ID,
      reason: GraphQLNullable<String>
    ) {
      self.requestId = requestId
      self.reason = reason
    }

    public var __variables: Variables? { [
      "requestId": requestId,
      "reason": reason
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("denyJoinRequest", DenyJoinRequest.self, arguments: [
          "requestId": .variable("requestId"),
          "reason": .variable("reason")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DenyJoinRequestMutation.Data.self
      ] }

      var denyJoinRequest: DenyJoinRequest { __data["denyJoinRequest"] }

      /// DenyJoinRequest
      ///
      /// Parent Type: `EventJoinRequest`
      struct DenyJoinRequest: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventJoinRequest }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("eventId", String.self),
          .field("user", User.self),
          .field("departmentType", GraphQLEnum<AssemblyOpsAPI.DepartmentType>?.self),
          .field("status", GraphQLEnum<AssemblyOpsAPI.JoinRequestStatus>.self),
          .field("note", String?.self),
          .field("createdAt", AssemblyOpsAPI.DateTime.self),
          .field("resolvedAt", AssemblyOpsAPI.DateTime?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          DenyJoinRequestMutation.Data.DenyJoinRequest.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var eventId: String { __data["eventId"] }
        var user: User { __data["user"] }
        var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType>? { __data["departmentType"] }
        var status: GraphQLEnum<AssemblyOpsAPI.JoinRequestStatus> { __data["status"] }
        var note: String? { __data["note"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }
        var resolvedAt: AssemblyOpsAPI.DateTime? { __data["resolvedAt"] }

        /// DenyJoinRequest.User
        ///
        /// Parent Type: `User`
        struct User: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.User }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("firstName", String.self),
            .field("lastName", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            DenyJoinRequestMutation.Data.DenyJoinRequest.User.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }
      }
    }
  }

}