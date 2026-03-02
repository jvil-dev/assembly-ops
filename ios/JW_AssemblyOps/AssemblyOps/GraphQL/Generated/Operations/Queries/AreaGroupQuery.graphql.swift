// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class AreaGroupQuery: GraphQLQuery {
    static let operationName: String = "AreaGroup"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query AreaGroup($areaId: ID!, $sessionId: ID!) { areaGroup(areaId: $areaId, sessionId: $sessionId) { __typename area { __typename id name description category } captain { __typename id session { __typename id name } eventVolunteer { __typename id user { __typename firstName lastName } } } members { __typename postName postId assignment { __typename id status isCaptain volunteer { __typename id firstName lastName congregation phone } checkIn { __typename id status checkInTime } } } } }"#
      ))

    public var areaId: ID
    public var sessionId: ID

    public init(
      areaId: ID,
      sessionId: ID
    ) {
      self.areaId = areaId
      self.sessionId = sessionId
    }

    public var __variables: Variables? { [
      "areaId": areaId,
      "sessionId": sessionId
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("areaGroup", AreaGroup?.self, arguments: [
          "areaId": .variable("areaId"),
          "sessionId": .variable("sessionId")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AreaGroupQuery.Data.self
      ] }

      var areaGroup: AreaGroup? { __data["areaGroup"] }

      /// AreaGroup
      ///
      /// Parent Type: `AreaGroup`
      struct AreaGroup: AssemblyOpsAPI.SelectionSet {
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
          AreaGroupQuery.Data.AreaGroup.self
        ] }

        var area: Area { __data["area"] }
        var captain: Captain? { __data["captain"] }
        var members: [Member] { __data["members"] }

        /// AreaGroup.Area
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
            AreaGroupQuery.Data.AreaGroup.Area.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var description: String? { __data["description"] }
          var category: String? { __data["category"] }
        }

        /// AreaGroup.Captain
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
            AreaGroupQuery.Data.AreaGroup.Captain.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var session: Session { __data["session"] }
          var eventVolunteer: EventVolunteer { __data["eventVolunteer"] }

          /// AreaGroup.Captain.Session
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
              AreaGroupQuery.Data.AreaGroup.Captain.Session.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
          }

          /// AreaGroup.Captain.EventVolunteer
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
              AreaGroupQuery.Data.AreaGroup.Captain.EventVolunteer.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var user: User { __data["user"] }

            /// AreaGroup.Captain.EventVolunteer.User
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
                AreaGroupQuery.Data.AreaGroup.Captain.EventVolunteer.User.self
              ] }

              var firstName: String { __data["firstName"] }
              var lastName: String { __data["lastName"] }
            }
          }
        }

        /// AreaGroup.Member
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
            AreaGroupQuery.Data.AreaGroup.Member.self
          ] }

          var postName: String { __data["postName"] }
          var postId: AssemblyOpsAPI.ID { __data["postId"] }
          var assignment: Assignment { __data["assignment"] }

          /// AreaGroup.Member.Assignment
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
              .field("isCaptain", Bool.self),
              .field("volunteer", Volunteer?.self),
              .field("checkIn", CheckIn?.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              AreaGroupQuery.Data.AreaGroup.Member.Assignment.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var status: GraphQLEnum<AssemblyOpsAPI.AssignmentStatus> { __data["status"] }
            var isCaptain: Bool { __data["isCaptain"] }
            var volunteer: Volunteer? { __data["volunteer"] }
            var checkIn: CheckIn? { __data["checkIn"] }

            /// AreaGroup.Member.Assignment.Volunteer
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
                AreaGroupQuery.Data.AreaGroup.Member.Assignment.Volunteer.self
              ] }

              var id: AssemblyOpsAPI.ID { __data["id"] }
              var firstName: String { __data["firstName"] }
              var lastName: String { __data["lastName"] }
              var congregation: String { __data["congregation"] }
              var phone: String? { __data["phone"] }
            }

            /// AreaGroup.Member.Assignment.CheckIn
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
                AreaGroupQuery.Data.AreaGroup.Member.Assignment.CheckIn.self
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