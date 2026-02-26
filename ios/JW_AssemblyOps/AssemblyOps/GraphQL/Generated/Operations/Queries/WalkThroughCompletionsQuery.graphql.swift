// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class WalkThroughCompletionsQuery: GraphQLQuery {
    static let operationName: String = "WalkThroughCompletions"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query WalkThroughCompletions($eventId: ID!, $sessionId: ID) { walkThroughCompletions(eventId: $eventId, sessionId: $sessionId) { __typename id session { __typename id name } eventVolunteer { __typename id user { __typename firstName lastName } } completedAt itemCount notes } }"#
      ))

    public var eventId: ID
    public var sessionId: GraphQLNullable<ID>

    public init(
      eventId: ID,
      sessionId: GraphQLNullable<ID>
    ) {
      self.eventId = eventId
      self.sessionId = sessionId
    }

    public var __variables: Variables? { [
      "eventId": eventId,
      "sessionId": sessionId
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("walkThroughCompletions", [WalkThroughCompletion].self, arguments: [
          "eventId": .variable("eventId"),
          "sessionId": .variable("sessionId")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        WalkThroughCompletionsQuery.Data.self
      ] }

      var walkThroughCompletions: [WalkThroughCompletion] { __data["walkThroughCompletions"] }

      /// WalkThroughCompletion
      ///
      /// Parent Type: `WalkThroughCompletion`
      struct WalkThroughCompletion: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.WalkThroughCompletion }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("session", Session.self),
          .field("eventVolunteer", EventVolunteer.self),
          .field("completedAt", String.self),
          .field("itemCount", Int.self),
          .field("notes", String?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          WalkThroughCompletionsQuery.Data.WalkThroughCompletion.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var session: Session { __data["session"] }
        var eventVolunteer: EventVolunteer { __data["eventVolunteer"] }
        var completedAt: String { __data["completedAt"] }
        var itemCount: Int { __data["itemCount"] }
        var notes: String? { __data["notes"] }

        /// WalkThroughCompletion.Session
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
            WalkThroughCompletionsQuery.Data.WalkThroughCompletion.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// WalkThroughCompletion.EventVolunteer
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
            WalkThroughCompletionsQuery.Data.WalkThroughCompletion.EventVolunteer.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var user: User { __data["user"] }

          /// WalkThroughCompletion.EventVolunteer.User
          ///
          /// Parent Type: `User`
          struct User: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.User }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("firstName", String.self),
              .field("lastName", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              WalkThroughCompletionsQuery.Data.WalkThroughCompletion.EventVolunteer.User.self
            ] }

            var firstName: String { __data["firstName"] }
            var lastName: String { __data["lastName"] }
          }
        }
      }
    }
  }

}