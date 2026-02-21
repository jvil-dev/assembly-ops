// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MyAttendantMeetingsQuery: GraphQLQuery {
    static let operationName: String = "MyAttendantMeetings"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query MyAttendantMeetings($eventId: ID!) { myAttendantMeetings(eventId: $eventId) { __typename id session { __typename id name date } meetingDate notes createdBy { __typename id firstName lastName } attendees { __typename id eventVolunteer { __typename id volunteerProfile { __typename firstName lastName } } } createdAt } }"#
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
        .field("myAttendantMeetings", [MyAttendantMeeting].self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MyAttendantMeetingsQuery.Data.self
      ] }

      var myAttendantMeetings: [MyAttendantMeeting] { __data["myAttendantMeetings"] }

      /// MyAttendantMeeting
      ///
      /// Parent Type: `AttendantMeeting`
      struct MyAttendantMeeting: AssemblyOpsAPI.SelectionSet {
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
          MyAttendantMeetingsQuery.Data.MyAttendantMeeting.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var session: Session { __data["session"] }
        var meetingDate: String { __data["meetingDate"] }
        var notes: String? { __data["notes"] }
        var createdBy: CreatedBy { __data["createdBy"] }
        var attendees: [Attendee] { __data["attendees"] }
        var createdAt: String { __data["createdAt"] }

        /// MyAttendantMeeting.Session
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
            MyAttendantMeetingsQuery.Data.MyAttendantMeeting.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var date: AssemblyOpsAPI.DateTime { __data["date"] }
        }

        /// MyAttendantMeeting.CreatedBy
        ///
        /// Parent Type: `Admin`
        struct CreatedBy: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Admin }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("firstName", String.self),
            .field("lastName", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MyAttendantMeetingsQuery.Data.MyAttendantMeeting.CreatedBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }

        /// MyAttendantMeeting.Attendee
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
            MyAttendantMeetingsQuery.Data.MyAttendantMeeting.Attendee.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var eventVolunteer: EventVolunteer { __data["eventVolunteer"] }

          /// MyAttendantMeeting.Attendee.EventVolunteer
          ///
          /// Parent Type: `EventVolunteer`
          struct EventVolunteer: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventVolunteer }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AssemblyOpsAPI.ID.self),
              .field("volunteerProfile", VolunteerProfile.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              MyAttendantMeetingsQuery.Data.MyAttendantMeeting.Attendee.EventVolunteer.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var volunteerProfile: VolunteerProfile { __data["volunteerProfile"] }

            /// MyAttendantMeeting.Attendee.EventVolunteer.VolunteerProfile
            ///
            /// Parent Type: `VolunteerProfile`
            struct VolunteerProfile: AssemblyOpsAPI.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.VolunteerProfile }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("firstName", String.self),
                .field("lastName", String.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                MyAttendantMeetingsQuery.Data.MyAttendantMeeting.Attendee.EventVolunteer.VolunteerProfile.self
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