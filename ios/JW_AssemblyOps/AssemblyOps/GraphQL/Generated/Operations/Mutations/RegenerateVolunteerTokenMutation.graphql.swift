// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class RegenerateVolunteerTokenMutation: GraphQLMutation {
    static let operationName: String = "RegenerateVolunteerToken"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RegenerateVolunteerToken($eventVolunteerId: ID!) { regenerateVolunteerToken(eventVolunteerId: $eventVolunteerId) { __typename eventVolunteer { __typename id volunteerId user { __typename id firstName lastName } } volunteerId token inviteMessage } }"#
      ))

    public var eventVolunteerId: ID

    public init(eventVolunteerId: ID) {
      self.eventVolunteerId = eventVolunteerId
    }

    public var __variables: Variables? { ["eventVolunteerId": eventVolunteerId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("regenerateVolunteerToken", RegenerateVolunteerToken.self, arguments: ["eventVolunteerId": .variable("eventVolunteerId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RegenerateVolunteerTokenMutation.Data.self
      ] }

      var regenerateVolunteerToken: RegenerateVolunteerToken { __data["regenerateVolunteerToken"] }

      /// RegenerateVolunteerToken
      ///
      /// Parent Type: `EventVolunteerCredentials`
      struct RegenerateVolunteerToken: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventVolunteerCredentials }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("eventVolunteer", EventVolunteer.self),
          .field("volunteerId", String.self),
          .field("token", String.self),
          .field("inviteMessage", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RegenerateVolunteerTokenMutation.Data.RegenerateVolunteerToken.self
        ] }

        var eventVolunteer: EventVolunteer { __data["eventVolunteer"] }
        var volunteerId: String { __data["volunteerId"] }
        var token: String { __data["token"] }
        var inviteMessage: String { __data["inviteMessage"] }

        /// RegenerateVolunteerToken.EventVolunteer
        ///
        /// Parent Type: `EventVolunteer`
        struct EventVolunteer: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventVolunteer }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("volunteerId", String.self),
            .field("user", User.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            RegenerateVolunteerTokenMutation.Data.RegenerateVolunteerToken.EventVolunteer.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var volunteerId: String { __data["volunteerId"] }
          var user: User { __data["user"] }

          /// RegenerateVolunteerToken.EventVolunteer.User
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
              RegenerateVolunteerTokenMutation.Data.RegenerateVolunteerToken.EventVolunteer.User.self
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