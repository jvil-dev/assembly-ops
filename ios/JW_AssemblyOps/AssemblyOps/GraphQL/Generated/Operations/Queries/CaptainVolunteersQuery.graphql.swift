// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CaptainVolunteersQuery: GraphQLQuery {
    static let operationName: String = "CaptainVolunteers"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query CaptainVolunteers($eventId: ID!, $departmentId: ID!) { captainVolunteers(eventId: $eventId, departmentId: $departmentId) { __typename id user { __typename id firstName lastName } } }"#
      ))

    public var eventId: ID
    public var departmentId: ID

    public init(
      eventId: ID,
      departmentId: ID
    ) {
      self.eventId = eventId
      self.departmentId = departmentId
    }

    public var __variables: Variables? { [
      "eventId": eventId,
      "departmentId": departmentId
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("captainVolunteers", [CaptainVolunteer].self, arguments: [
          "eventId": .variable("eventId"),
          "departmentId": .variable("departmentId")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CaptainVolunteersQuery.Data.self
      ] }

      var captainVolunteers: [CaptainVolunteer] { __data["captainVolunteers"] }

      /// CaptainVolunteer
      ///
      /// Parent Type: `EventVolunteer`
      struct CaptainVolunteer: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventVolunteer }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("user", User.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CaptainVolunteersQuery.Data.CaptainVolunteer.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var user: User { __data["user"] }

        /// CaptainVolunteer.User
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
            CaptainVolunteersQuery.Data.CaptainVolunteer.User.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }
      }
    }
  }

}