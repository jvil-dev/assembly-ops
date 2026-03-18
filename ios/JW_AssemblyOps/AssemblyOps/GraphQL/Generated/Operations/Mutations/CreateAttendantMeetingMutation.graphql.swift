// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CreateAttendantMeetingMutation: GraphQLMutation {
    static let operationName: String = "CreateAttendantMeeting"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CreateAttendantMeeting($input: CreateAttendantMeetingInput!) { createAttendantMeeting(input: $input) { __typename id name session { __typename id name } meetingDate notes attendees { __typename id eventVolunteer { __typename id user { __typename firstName lastName } } } createdAt } }"#
      ))

    public var input: CreateAttendantMeetingInput

    public init(input: CreateAttendantMeetingInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("createAttendantMeeting", CreateAttendantMeeting.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CreateAttendantMeetingMutation.Data.self
      ] }

      var createAttendantMeeting: CreateAttendantMeeting { __data["createAttendantMeeting"] }

      /// CreateAttendantMeeting
      ///
      /// Parent Type: `AttendantMeeting`
      struct CreateAttendantMeeting: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AttendantMeeting }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String?.self),
          .field("session", Session.self),
          .field("meetingDate", String.self),
          .field("notes", String?.self),
          .field("attendees", [Attendee].self),
          .field("createdAt", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CreateAttendantMeetingMutation.Data.CreateAttendantMeeting.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String? { __data["name"] }
        var session: Session { __data["session"] }
        var meetingDate: String { __data["meetingDate"] }
        var notes: String? { __data["notes"] }
        var attendees: [Attendee] { __data["attendees"] }
        var createdAt: String { __data["createdAt"] }

        /// CreateAttendantMeeting.Session
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
            CreateAttendantMeetingMutation.Data.CreateAttendantMeeting.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// CreateAttendantMeeting.Attendee
        ///
        /// Parent Type: `MeetingAttendance`
        struct Attendee: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.MeetingAttendance }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("eventVolunteer", EventVolunteer.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CreateAttendantMeetingMutation.Data.CreateAttendantMeeting.Attendee.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var eventVolunteer: EventVolunteer { __data["eventVolunteer"] }

          /// CreateAttendantMeeting.Attendee.EventVolunteer
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
              CreateAttendantMeetingMutation.Data.CreateAttendantMeeting.Attendee.EventVolunteer.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var user: User { __data["user"] }

            /// CreateAttendantMeeting.Attendee.EventVolunteer.User
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
                CreateAttendantMeetingMutation.Data.CreateAttendantMeeting.Attendee.EventVolunteer.User.self
              ] }

              var firstName: String { __data["firstName"] }
              var lastName: String { __data["lastName"] }
            }
          }
        }
      }
    }
  }

}