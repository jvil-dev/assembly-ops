// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MyAreaGroupsQuery: GraphQLQuery {
    static let operationName: String = "MyAreaGroups"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query MyAreaGroups { myAreaGroups { __typename area { __typename id name description category } captain { __typename id session { __typename id name date startTime endTime } eventVolunteer { __typename id volunteerId volunteerProfile { __typename firstName lastName } } } members { __typename postName postId assignment { __typename id status volunteer { __typename id firstName lastName congregation phone } checkIn { __typename id status checkInTime } } } } }"#
      ))

    public init() {}

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("myAreaGroups", [MyAreaGroup].self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MyAreaGroupsQuery.Data.self
      ] }

      var myAreaGroups: [MyAreaGroup] { __data["myAreaGroups"] }

      /// MyAreaGroup
      ///
      /// Parent Type: `AreaGroup`
      struct MyAreaGroup: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AreaGroup }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("area", Area.self),
          .field("captain", Captain?.self),
          .field("members", [Member].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MyAreaGroupsQuery.Data.MyAreaGroup.self
        ] }

        var area: Area { __data["area"] }
        var captain: Captain? { __data["captain"] }
        var members: [Member] { __data["members"] }

        /// MyAreaGroup.Area
        ///
        /// Parent Type: `Area`
        struct Area: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Area }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
            .field("description", String?.self),
            .field("category", String?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MyAreaGroupsQuery.Data.MyAreaGroup.Area.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var description: String? { __data["description"] }
          var category: String? { __data["category"] }
        }

        /// MyAreaGroup.Captain
        ///
        /// Parent Type: `AreaCaptainAssignment`
        struct Captain: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AreaCaptainAssignment }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("session", Session.self),
            .field("eventVolunteer", EventVolunteer.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MyAreaGroupsQuery.Data.MyAreaGroup.Captain.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var session: Session { __data["session"] }
          var eventVolunteer: EventVolunteer { __data["eventVolunteer"] }

          /// MyAreaGroup.Captain.Session
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
              .field("startTime", AssemblyOpsAPI.DateTime.self),
              .field("endTime", AssemblyOpsAPI.DateTime.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              MyAreaGroupsQuery.Data.MyAreaGroup.Captain.Session.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
            var date: AssemblyOpsAPI.DateTime { __data["date"] }
            var startTime: AssemblyOpsAPI.DateTime { __data["startTime"] }
            var endTime: AssemblyOpsAPI.DateTime { __data["endTime"] }
          }

          /// MyAreaGroup.Captain.EventVolunteer
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
              .field("volunteerProfile", VolunteerProfile.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              MyAreaGroupsQuery.Data.MyAreaGroup.Captain.EventVolunteer.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var volunteerId: String { __data["volunteerId"] }
            var volunteerProfile: VolunteerProfile { __data["volunteerProfile"] }

            /// MyAreaGroup.Captain.EventVolunteer.VolunteerProfile
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
                MyAreaGroupsQuery.Data.MyAreaGroup.Captain.EventVolunteer.VolunteerProfile.self
              ] }

              var firstName: String { __data["firstName"] }
              var lastName: String { __data["lastName"] }
            }
          }
        }

        /// MyAreaGroup.Member
        ///
        /// Parent Type: `AreaGroupMember`
        struct Member: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AreaGroupMember }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("postName", String.self),
            .field("postId", AssemblyOpsAPI.ID.self),
            .field("assignment", Assignment.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MyAreaGroupsQuery.Data.MyAreaGroup.Member.self
          ] }

          var postName: String { __data["postName"] }
          var postId: AssemblyOpsAPI.ID { __data["postId"] }
          var assignment: Assignment { __data["assignment"] }

          /// MyAreaGroup.Member.Assignment
          ///
          /// Parent Type: `ScheduleAssignment`
          struct Assignment: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.ScheduleAssignment }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AssemblyOpsAPI.ID.self),
              .field("status", GraphQLEnum<AssemblyOpsAPI.AssignmentStatus>.self),
              .field("volunteer", Volunteer.self),
              .field("checkIn", CheckIn?.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              MyAreaGroupsQuery.Data.MyAreaGroup.Member.Assignment.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var status: GraphQLEnum<AssemblyOpsAPI.AssignmentStatus> { __data["status"] }
            var volunteer: Volunteer { __data["volunteer"] }
            var checkIn: CheckIn? { __data["checkIn"] }

            /// MyAreaGroup.Member.Assignment.Volunteer
            ///
            /// Parent Type: `Volunteer`
            struct Volunteer: AssemblyOpsAPI.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Volunteer }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("id", AssemblyOpsAPI.ID.self),
                .field("firstName", String.self),
                .field("lastName", String.self),
                .field("congregation", String.self),
                .field("phone", String?.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                MyAreaGroupsQuery.Data.MyAreaGroup.Member.Assignment.Volunteer.self
              ] }

              var id: AssemblyOpsAPI.ID { __data["id"] }
              var firstName: String { __data["firstName"] }
              var lastName: String { __data["lastName"] }
              var congregation: String { __data["congregation"] }
              var phone: String? { __data["phone"] }
            }

            /// MyAreaGroup.Member.Assignment.CheckIn
            ///
            /// Parent Type: `CheckIn`
            struct CheckIn: AssemblyOpsAPI.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.CheckIn }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("id", AssemblyOpsAPI.ID.self),
                .field("status", GraphQLEnum<AssemblyOpsAPI.CheckInStatus>.self),
                .field("checkInTime", AssemblyOpsAPI.DateTime.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                MyAreaGroupsQuery.Data.MyAreaGroup.Member.Assignment.CheckIn.self
              ] }

              var id: AssemblyOpsAPI.ID { __data["id"] }
              var status: GraphQLEnum<AssemblyOpsAPI.CheckInStatus> { __data["status"] }
              var checkInTime: AssemblyOpsAPI.DateTime { __data["checkInTime"] }
            }
          }
        }
      }
    }
  }

}