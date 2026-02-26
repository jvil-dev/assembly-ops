// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class AddVolunteerToEventMutation: GraphQLMutation {
    static let operationName: String = "AddVolunteerToEvent"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation AddVolunteerToEvent($input: AddVolunteerToEventInput!) { addVolunteerToEvent(input: $input) { __typename eventVolunteer { __typename id volunteerId user { __typename id firstName lastName } } volunteerId token inviteMessage } }"#
      ))

    public var input: AddVolunteerToEventInput

    public init(input: AddVolunteerToEventInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("addVolunteerToEvent", AddVolunteerToEvent.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AddVolunteerToEventMutation.Data.self
      ] }

      var addVolunteerToEvent: AddVolunteerToEvent { __data["addVolunteerToEvent"] }

      /// AddVolunteerToEvent
      ///
      /// Parent Type: `EventVolunteerCredentials`
      struct AddVolunteerToEvent: AssemblyOpsAPI.SelectionSet {
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
          AddVolunteerToEventMutation.Data.AddVolunteerToEvent.self
        ] }

        var eventVolunteer: EventVolunteer { __data["eventVolunteer"] }
        var volunteerId: String { __data["volunteerId"] }
        var token: String { __data["token"] }
        var inviteMessage: String { __data["inviteMessage"] }

        /// AddVolunteerToEvent.EventVolunteer
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
            AddVolunteerToEventMutation.Data.AddVolunteerToEvent.EventVolunteer.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var volunteerId: String { __data["volunteerId"] }
          var user: User { __data["user"] }

          /// AddVolunteerToEvent.EventVolunteer.User
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
              AddVolunteerToEventMutation.Data.AddVolunteerToEvent.EventVolunteer.User.self
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