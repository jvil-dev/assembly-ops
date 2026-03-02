// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class SetAreaCaptainMutation: GraphQLMutation {
    static let operationName: String = "SetAreaCaptain"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation SetAreaCaptain($input: SetAreaCaptainInput!) { setAreaCaptain(input: $input) { __typename id status respondedAt declineReason acceptedDeadline forceAssigned area { __typename id name } session { __typename id name } eventVolunteer { __typename id user { __typename firstName lastName } } } }"#
      ))

    public var input: SetAreaCaptainInput

    public init(input: SetAreaCaptainInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("setAreaCaptain", SetAreaCaptain.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SetAreaCaptainMutation.Data.self
      ] }

      var setAreaCaptain: SetAreaCaptain { __data["setAreaCaptain"] }

      /// SetAreaCaptain
      ///
      /// Parent Type: `AreaCaptainAssignment`
      struct SetAreaCaptain: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AreaCaptainAssignment }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("status", GraphQLEnum<AssemblyOpsAPI.AssignmentStatus>.self),
          .field("respondedAt", AssemblyOpsAPI.DateTime?.self),
          .field("declineReason", String?.self),
          .field("acceptedDeadline", AssemblyOpsAPI.DateTime?.self),
          .field("forceAssigned", Bool.self),
          .field("area", Area.self),
          .field("session", Session.self),
          .field("eventVolunteer", EventVolunteer.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SetAreaCaptainMutation.Data.SetAreaCaptain.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var status: GraphQLEnum<AssemblyOpsAPI.AssignmentStatus> { __data["status"] }
        var respondedAt: AssemblyOpsAPI.DateTime? { __data["respondedAt"] }
        var declineReason: String? { __data["declineReason"] }
        var acceptedDeadline: AssemblyOpsAPI.DateTime? { __data["acceptedDeadline"] }
        var forceAssigned: Bool { __data["forceAssigned"] }
        var area: Area { __data["area"] }
        var session: Session { __data["session"] }
        var eventVolunteer: EventVolunteer { __data["eventVolunteer"] }

        /// SetAreaCaptain.Area
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
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SetAreaCaptainMutation.Data.SetAreaCaptain.Area.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// SetAreaCaptain.Session
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
            SetAreaCaptainMutation.Data.SetAreaCaptain.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// SetAreaCaptain.EventVolunteer
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
            SetAreaCaptainMutation.Data.SetAreaCaptain.EventVolunteer.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var user: User { __data["user"] }

          /// SetAreaCaptain.EventVolunteer.User
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
              SetAreaCaptainMutation.Data.SetAreaCaptain.EventVolunteer.User.self
            ] }

            var firstName: String { __data["firstName"] }
            var lastName: String { __data["lastName"] }
          }
        }
      }
    }
  }

}