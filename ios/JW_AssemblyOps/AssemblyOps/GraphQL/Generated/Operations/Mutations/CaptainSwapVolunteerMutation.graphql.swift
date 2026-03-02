// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CaptainSwapVolunteerMutation: GraphQLMutation {
    static let operationName: String = "CaptainSwapVolunteer"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CaptainSwapVolunteer($input: CaptainSwapInput!, $eventId: ID!) { captainSwapVolunteer(input: $input, eventId: $eventId) { __typename id status post { __typename id name } session { __typename id name } shift { __typename id name startTime endTime } eventVolunteer { __typename id user { __typename id firstName lastName } } } }"#
      ))

    public var input: CaptainSwapInput
    public var eventId: ID

    public init(
      input: CaptainSwapInput,
      eventId: ID
    ) {
      self.input = input
      self.eventId = eventId
    }

    public var __variables: Variables? { [
      "input": input,
      "eventId": eventId
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("captainSwapVolunteer", CaptainSwapVolunteer.self, arguments: [
          "input": .variable("input"),
          "eventId": .variable("eventId")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CaptainSwapVolunteerMutation.Data.self
      ] }

      var captainSwapVolunteer: CaptainSwapVolunteer { __data["captainSwapVolunteer"] }

      /// CaptainSwapVolunteer
      ///
      /// Parent Type: `ScheduleAssignment`
      struct CaptainSwapVolunteer: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.ScheduleAssignment }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("status", GraphQLEnum<AssemblyOpsAPI.AssignmentStatus>.self),
          .field("post", Post.self),
          .field("session", Session.self),
          .field("shift", Shift?.self),
          .field("eventVolunteer", EventVolunteer?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CaptainSwapVolunteerMutation.Data.CaptainSwapVolunteer.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var status: GraphQLEnum<AssemblyOpsAPI.AssignmentStatus> { __data["status"] }
        var post: Post { __data["post"] }
        var session: Session { __data["session"] }
        var shift: Shift? { __data["shift"] }
        var eventVolunteer: EventVolunteer? { __data["eventVolunteer"] }

        /// CaptainSwapVolunteer.Post
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
            CaptainSwapVolunteerMutation.Data.CaptainSwapVolunteer.Post.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// CaptainSwapVolunteer.Session
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
            CaptainSwapVolunteerMutation.Data.CaptainSwapVolunteer.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// CaptainSwapVolunteer.Shift
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
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CaptainSwapVolunteerMutation.Data.CaptainSwapVolunteer.Shift.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var startTime: AssemblyOpsAPI.DateTime { __data["startTime"] }
          var endTime: AssemblyOpsAPI.DateTime { __data["endTime"] }
        }

        /// CaptainSwapVolunteer.EventVolunteer
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
            CaptainSwapVolunteerMutation.Data.CaptainSwapVolunteer.EventVolunteer.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var user: User { __data["user"] }

          /// CaptainSwapVolunteer.EventVolunteer.User
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
              CaptainSwapVolunteerMutation.Data.CaptainSwapVolunteer.EventVolunteer.User.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var firstName: String { __data["firstName"] }
            var lastName: String { __data["lastName"] }
          }
        }
      }
    }
  }

}