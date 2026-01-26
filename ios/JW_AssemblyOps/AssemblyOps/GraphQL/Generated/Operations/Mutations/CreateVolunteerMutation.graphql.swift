// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CreateVolunteerMutation: GraphQLMutation {
    static let operationName: String = "CreateVolunteer"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CreateVolunteer($eventId: ID!, $input: CreateVolunteerInput!) { createVolunteer(eventId: $eventId, input: $input) { __typename id volunteerId token firstName lastName congregation } }"#
      ))

    public var eventId: ID
    public var input: CreateVolunteerInput

    public init(
      eventId: ID,
      input: CreateVolunteerInput
    ) {
      self.eventId = eventId
      self.input = input
    }

    public var __variables: Variables? { [
      "eventId": eventId,
      "input": input
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("createVolunteer", CreateVolunteer.self, arguments: [
          "eventId": .variable("eventId"),
          "input": .variable("input")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CreateVolunteerMutation.Data.self
      ] }

      var createVolunteer: CreateVolunteer { __data["createVolunteer"] }

      /// CreateVolunteer
      ///
      /// Parent Type: `CreatedVolunteer`
      struct CreateVolunteer: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.CreatedVolunteer }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("volunteerId", String.self),
          .field("token", String.self),
          .field("firstName", String.self),
          .field("lastName", String.self),
          .field("congregation", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CreateVolunteerMutation.Data.CreateVolunteer.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var volunteerId: String { __data["volunteerId"] }
        var token: String { __data["token"] }
        var firstName: String { __data["firstName"] }
        var lastName: String { __data["lastName"] }
        var congregation: String { __data["congregation"] }
      }
    }
  }

}