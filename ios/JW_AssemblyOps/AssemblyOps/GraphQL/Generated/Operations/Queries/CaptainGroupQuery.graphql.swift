// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CaptainGroupQuery: GraphQLQuery {
    static let operationName: String = "CaptainGroup"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query CaptainGroup($postId: ID!, $sessionId: ID!) { captainGroup(postId: $postId, sessionId: $sessionId) { __typename captain { __typename id volunteer { __typename id firstName lastName } } members { __typename id status volunteer { __typename id firstName lastName congregation phone } checkIn { __typename id status checkInTime } } } }"#
      ))

    public var postId: ID
    public var sessionId: ID

    public init(
      postId: ID,
      sessionId: ID
    ) {
      self.postId = postId
      self.sessionId = sessionId
    }

    public var __variables: Variables? { [
      "postId": postId,
      "sessionId": sessionId
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("captainGroup", CaptainGroup?.self, arguments: [
          "postId": .variable("postId"),
          "sessionId": .variable("sessionId")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CaptainGroupQuery.Data.self
      ] }

      var captainGroup: CaptainGroup? { __data["captainGroup"] }

      /// CaptainGroup
      ///
      /// Parent Type: `CaptainGroup`
      struct CaptainGroup: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.CaptainGroup }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("captain", Captain.self),
          .field("members", [Member].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CaptainGroupQuery.Data.CaptainGroup.self
        ] }

        var captain: Captain { __data["captain"] }
        var members: [Member] { __data["members"] }

        /// CaptainGroup.Captain
        ///
        /// Parent Type: `ScheduleAssignment`
        struct Captain: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.ScheduleAssignment }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("volunteer", Volunteer.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CaptainGroupQuery.Data.CaptainGroup.Captain.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var volunteer: Volunteer { __data["volunteer"] }

          /// CaptainGroup.Captain.Volunteer
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
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              CaptainGroupQuery.Data.CaptainGroup.Captain.Volunteer.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var firstName: String { __data["firstName"] }
            var lastName: String { __data["lastName"] }
          }
        }

        /// CaptainGroup.Member
        ///
        /// Parent Type: `ScheduleAssignment`
        struct Member: AssemblyOpsAPI.SelectionSet {
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
            CaptainGroupQuery.Data.CaptainGroup.Member.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var status: GraphQLEnum<AssemblyOpsAPI.AssignmentStatus> { __data["status"] }
          var volunteer: Volunteer { __data["volunteer"] }
          var checkIn: CheckIn? { __data["checkIn"] }

          /// CaptainGroup.Member.Volunteer
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
              CaptainGroupQuery.Data.CaptainGroup.Member.Volunteer.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var firstName: String { __data["firstName"] }
            var lastName: String { __data["lastName"] }
            var congregation: String { __data["congregation"] }
            var phone: String? { __data["phone"] }
          }

          /// CaptainGroup.Member.CheckIn
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
              CaptainGroupQuery.Data.CaptainGroup.Member.CheckIn.self
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