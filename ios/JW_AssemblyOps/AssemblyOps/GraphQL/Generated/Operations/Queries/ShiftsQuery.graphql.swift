// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class ShiftsQuery: GraphQLQuery {
    static let operationName: String = "Shifts"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Shifts($sessionId: ID!, $postId: ID) { shifts(sessionId: $sessionId, postId: $postId) { __typename id name startTime endTime session { __typename id name } post { __typename id name } createdAt createdBy { __typename id firstName lastName } assignments { __typename id eventVolunteer { __typename id user { __typename id firstName lastName } } status checkIn { __typename id } } } }"#
      ))

    public var sessionId: ID
    public var postId: GraphQLNullable<ID>

    public init(
      sessionId: ID,
      postId: GraphQLNullable<ID>
    ) {
      self.sessionId = sessionId
      self.postId = postId
    }

    public var __variables: Variables? { [
      "sessionId": sessionId,
      "postId": postId
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("shifts", [Shift].self, arguments: [
          "sessionId": .variable("sessionId"),
          "postId": .variable("postId")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ShiftsQuery.Data.self
      ] }

      var shifts: [Shift] { __data["shifts"] }

      /// Shift
      ///
      /// Parent Type: `Shift`
      struct Shift: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Shift }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("startTime", AssemblyOpsAPI.DateTime.self),
          .field("endTime", AssemblyOpsAPI.DateTime.self),
          .field("session", Session.self),
          .field("post", Post.self),
          .field("createdAt", AssemblyOpsAPI.DateTime.self),
          .field("createdBy", CreatedBy?.self),
          .field("assignments", [Assignment].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ShiftsQuery.Data.Shift.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var startTime: AssemblyOpsAPI.DateTime { __data["startTime"] }
        var endTime: AssemblyOpsAPI.DateTime { __data["endTime"] }
        var session: Session { __data["session"] }
        var post: Post { __data["post"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }
        var createdBy: CreatedBy? { __data["createdBy"] }
        var assignments: [Assignment] { __data["assignments"] }

        /// Shift.Session
        ///
        /// Parent Type: `Session`
        struct Session: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Session }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ShiftsQuery.Data.Shift.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// Shift.Post
        ///
        /// Parent Type: `Post`
        struct Post: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Post }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ShiftsQuery.Data.Shift.Post.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// Shift.CreatedBy
        ///
        /// Parent Type: `User`
        struct CreatedBy: AssemblyOpsAPI.SelectionSet {
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
            ShiftsQuery.Data.Shift.CreatedBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }

        /// Shift.Assignment
        ///
        /// Parent Type: `ScheduleAssignment`
        struct Assignment: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.ScheduleAssignment }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("eventVolunteer", EventVolunteer?.self),
            .field("status", GraphQLEnum<AssemblyOpsAPI.AssignmentStatus>.self),
            .field("checkIn", CheckIn?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ShiftsQuery.Data.Shift.Assignment.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var eventVolunteer: EventVolunteer? { __data["eventVolunteer"] }
          var status: GraphQLEnum<AssemblyOpsAPI.AssignmentStatus> { __data["status"] }
          var checkIn: CheckIn? { __data["checkIn"] }

          /// Shift.Assignment.EventVolunteer
          ///
          /// Parent Type: `EventVolunteer`
          struct EventVolunteer: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventVolunteer }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AssemblyOpsAPI.ID.self),
              .field("user", User.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              ShiftsQuery.Data.Shift.Assignment.EventVolunteer.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var user: User { __data["user"] }

            /// Shift.Assignment.EventVolunteer.User
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
                ShiftsQuery.Data.Shift.Assignment.EventVolunteer.User.self
              ] }

              var id: AssemblyOpsAPI.ID { __data["id"] }
              var firstName: String { __data["firstName"] }
              var lastName: String { __data["lastName"] }
            }
          }

          /// Shift.Assignment.CheckIn
          ///
          /// Parent Type: `CheckIn`
          struct CheckIn: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.CheckIn }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AssemblyOpsAPI.ID.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              ShiftsQuery.Data.Shift.Assignment.CheckIn.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
          }
        }
      }
    }
  }

}