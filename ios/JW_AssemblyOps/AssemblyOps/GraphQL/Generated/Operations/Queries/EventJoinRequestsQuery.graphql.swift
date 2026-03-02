// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class EventJoinRequestsQuery: GraphQLQuery {
    static let operationName: String = "EventJoinRequests"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query EventJoinRequests($eventId: ID!, $status: JoinRequestStatus) { eventJoinRequests(eventId: $eventId, status: $status) { __typename id eventId user { __typename id userId firstName lastName congregation appointmentStatus } departmentType status note createdAt resolvedAt } }"#
      ))

    public var eventId: ID
    public var status: GraphQLNullable<GraphQLEnum<JoinRequestStatus>>

    public init(
      eventId: ID,
      status: GraphQLNullable<GraphQLEnum<JoinRequestStatus>>
    ) {
      self.eventId = eventId
      self.status = status
    }

    public var __variables: Variables? { [
      "eventId": eventId,
      "status": status
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("eventJoinRequests", [EventJoinRequest].self, arguments: [
          "eventId": .variable("eventId"),
          "status": .variable("status")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        EventJoinRequestsQuery.Data.self
      ] }

      var eventJoinRequests: [EventJoinRequest] { __data["eventJoinRequests"] }

      /// EventJoinRequest
      ///
      /// Parent Type: `EventJoinRequest`
      struct EventJoinRequest: AssemblyOpsAPI.SelectionSet {
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
          EventJoinRequestsQuery.Data.EventJoinRequest.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var eventId: String { __data["eventId"] }
        var user: User { __data["user"] }
        var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType>? { __data["departmentType"] }
        var status: GraphQLEnum<AssemblyOpsAPI.JoinRequestStatus> { __data["status"] }
        var note: String? { __data["note"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }
        var resolvedAt: AssemblyOpsAPI.DateTime? { __data["resolvedAt"] }

        /// EventJoinRequest.User
        ///
        /// Parent Type: `User`
        struct User: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.User }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("userId", String.self),
            .field("firstName", String.self),
            .field("lastName", String.self),
            .field("congregation", String?.self),
            .field("appointmentStatus", GraphQLEnum<AssemblyOpsAPI.AppointmentStatus>?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            EventJoinRequestsQuery.Data.EventJoinRequest.User.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var userId: String { __data["userId"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
          var congregation: String? { __data["congregation"] }
          var appointmentStatus: GraphQLEnum<AssemblyOpsAPI.AppointmentStatus>? { __data["appointmentStatus"] }
        }
      }
    }
  }

}