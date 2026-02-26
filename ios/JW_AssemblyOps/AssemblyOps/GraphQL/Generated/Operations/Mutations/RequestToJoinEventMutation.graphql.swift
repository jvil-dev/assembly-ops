// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class RequestToJoinEventMutation: GraphQLMutation {
    static let operationName: String = "RequestToJoinEvent"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RequestToJoinEvent($eventId: ID!, $departmentType: DepartmentType, $note: String) { requestToJoinEvent( eventId: $eventId departmentType: $departmentType note: $note ) { __typename id eventId user { __typename id userId firstName lastName } departmentType status note createdAt } }"#
      ))

    public var eventId: ID
    public var departmentType: GraphQLNullable<GraphQLEnum<DepartmentType>>
    public var note: GraphQLNullable<String>

    public init(
      eventId: ID,
      departmentType: GraphQLNullable<GraphQLEnum<DepartmentType>>,
      note: GraphQLNullable<String>
    ) {
      self.eventId = eventId
      self.departmentType = departmentType
      self.note = note
    }

    public var __variables: Variables? { [
      "eventId": eventId,
      "departmentType": departmentType,
      "note": note
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("requestToJoinEvent", RequestToJoinEvent.self, arguments: [
          "eventId": .variable("eventId"),
          "departmentType": .variable("departmentType"),
          "note": .variable("note")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RequestToJoinEventMutation.Data.self
      ] }

      var requestToJoinEvent: RequestToJoinEvent { __data["requestToJoinEvent"] }

      /// RequestToJoinEvent
      ///
      /// Parent Type: `EventJoinRequest`
      struct RequestToJoinEvent: AssemblyOpsAPI.SelectionSet {
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
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RequestToJoinEventMutation.Data.RequestToJoinEvent.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var eventId: String { __data["eventId"] }
        var user: User { __data["user"] }
        var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType>? { __data["departmentType"] }
        var status: GraphQLEnum<AssemblyOpsAPI.JoinRequestStatus> { __data["status"] }
        var note: String? { __data["note"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }

        /// RequestToJoinEvent.User
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
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            RequestToJoinEventMutation.Data.RequestToJoinEvent.User.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var userId: String { __data["userId"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }
      }
    }
  }

}