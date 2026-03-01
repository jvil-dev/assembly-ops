// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CreateAVSafetyBriefingMutation: GraphQLMutation {
    static let operationName: String = "CreateAVSafetyBriefing"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CreateAVSafetyBriefing($input: CreateAVSafetyBriefingInput!) { createAVSafetyBriefing(input: $input) { __typename id topic notes conductedBy { __typename id firstName lastName } conductedAt attendees { __typename id eventVolunteer { __typename id user { __typename firstName lastName } } } attendeeCount } }"#
      ))

    public var input: CreateAVSafetyBriefingInput

    public init(input: CreateAVSafetyBriefingInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("createAVSafetyBriefing", CreateAVSafetyBriefing.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CreateAVSafetyBriefingMutation.Data.self
      ] }

      var createAVSafetyBriefing: CreateAVSafetyBriefing { __data["createAVSafetyBriefing"] }

      /// CreateAVSafetyBriefing
      ///
      /// Parent Type: `AVSafetyBriefing`
      struct CreateAVSafetyBriefing: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVSafetyBriefing }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("topic", String.self),
          .field("notes", String?.self),
          .field("conductedBy", ConductedBy.self),
          .field("conductedAt", String.self),
          .field("attendees", [Attendee].self),
          .field("attendeeCount", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CreateAVSafetyBriefingMutation.Data.CreateAVSafetyBriefing.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var topic: String { __data["topic"] }
        var notes: String? { __data["notes"] }
        var conductedBy: ConductedBy { __data["conductedBy"] }
        var conductedAt: String { __data["conductedAt"] }
        var attendees: [Attendee] { __data["attendees"] }
        var attendeeCount: Int { __data["attendeeCount"] }

        /// CreateAVSafetyBriefing.ConductedBy
        ///
        /// Parent Type: `User`
        struct ConductedBy: AssemblyOpsAPI.SelectionSet {
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
            CreateAVSafetyBriefingMutation.Data.CreateAVSafetyBriefing.ConductedBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }

        /// CreateAVSafetyBriefing.Attendee
        ///
        /// Parent Type: `AVSafetyBriefingAttendee`
        struct Attendee: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVSafetyBriefingAttendee }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("eventVolunteer", EventVolunteer.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CreateAVSafetyBriefingMutation.Data.CreateAVSafetyBriefing.Attendee.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var eventVolunteer: EventVolunteer { __data["eventVolunteer"] }

          /// CreateAVSafetyBriefing.Attendee.EventVolunteer
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
              CreateAVSafetyBriefingMutation.Data.CreateAVSafetyBriefing.Attendee.EventVolunteer.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var user: User { __data["user"] }

            /// CreateAVSafetyBriefing.Attendee.EventVolunteer.User
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
                CreateAVSafetyBriefingMutation.Data.CreateAVSafetyBriefing.Attendee.EventVolunteer.User.self
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