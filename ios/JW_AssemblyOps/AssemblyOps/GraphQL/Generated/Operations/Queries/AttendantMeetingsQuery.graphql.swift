// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class AttendantMeetingsQuery: GraphQLQuery {
    static let operationName: String = "AttendantMeetings"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query AttendantMeetings($eventId: ID!) { attendantMeetings(eventId: $eventId) { __typename id session { __typename id name date } meetingDate notes createdBy { __typename id firstName lastName } attendees { __typename id eventVolunteer { __typename id user { __typename firstName lastName } } } createdAt } }"#
      ))

    public var eventId: ID

    public init(eventId: ID) {
      self.eventId = eventId
    }

    public var __variables: Variables? { ["eventId": eventId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("attendantMeetings", [AttendantMeeting].self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AttendantMeetingsQuery.Data.self
      ] }

      var attendantMeetings: [AttendantMeeting] { __data["attendantMeetings"] }

      /// AttendantMeeting
      ///
      /// Parent Type: `AttendantMeeting`
      struct AttendantMeeting: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AttendantMeeting }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("session", Session.self),
          .field("meetingDate", String.self),
          .field("notes", String?.self),
          .field("createdBy", CreatedBy.self),
          .field("attendees", [Attendee].self),
          .field("createdAt", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AttendantMeetingsQuery.Data.AttendantMeeting.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var session: Session { __data["session"] }
        var meetingDate: String { __data["meetingDate"] }
        var notes: String? { __data["notes"] }
        var createdBy: CreatedBy { __data["createdBy"] }
        var attendees: [Attendee] { __data["attendees"] }
        var createdAt: String { __data["createdAt"] }

        /// AttendantMeeting.Session
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
            .field("date", AssemblyOpsAPI.DateTime.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            AttendantMeetingsQuery.Data.AttendantMeeting.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var date: AssemblyOpsAPI.DateTime { __data["date"] }
        }

        /// AttendantMeeting.CreatedBy
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
            AttendantMeetingsQuery.Data.AttendantMeeting.CreatedBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }

        /// AttendantMeeting.Attendee
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
            AttendantMeetingsQuery.Data.AttendantMeeting.Attendee.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var eventVolunteer: EventVolunteer { __data["eventVolunteer"] }

          /// AttendantMeeting.Attendee.EventVolunteer
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
              AttendantMeetingsQuery.Data.AttendantMeeting.Attendee.EventVolunteer.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var user: User { __data["user"] }

            /// AttendantMeeting.Attendee.EventVolunteer.User
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
                AttendantMeetingsQuery.Data.AttendantMeeting.Attendee.EventVolunteer.User.self
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