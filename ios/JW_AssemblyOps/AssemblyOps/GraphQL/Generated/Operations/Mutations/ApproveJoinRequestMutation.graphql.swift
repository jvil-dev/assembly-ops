// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class ApproveJoinRequestMutation: GraphQLMutation {
    static let operationName: String = "ApproveJoinRequest"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation ApproveJoinRequest($requestId: ID!) { approveJoinRequest(requestId: $requestId) { __typename eventVolunteer { __typename id volunteerId user { __typename id firstName lastName } event { __typename id name } department { __typename id name departmentType } } volunteerId token inviteMessage } }"#
      ))

    public var requestId: ID

    public init(requestId: ID) {
      self.requestId = requestId
    }

    public var __variables: Variables? { ["requestId": requestId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("approveJoinRequest", ApproveJoinRequest.self, arguments: ["requestId": .variable("requestId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ApproveJoinRequestMutation.Data.self
      ] }

      var approveJoinRequest: ApproveJoinRequest { __data["approveJoinRequest"] }

      /// ApproveJoinRequest
      ///
      /// Parent Type: `EventVolunteerCredentials`
      struct ApproveJoinRequest: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventVolunteerCredentials }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("eventVolunteer", EventVolunteer.self),
          .field("volunteerId", String.self),
          .field("token", String.self),
          .field("inviteMessage", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ApproveJoinRequestMutation.Data.ApproveJoinRequest.self
        ] }

        var eventVolunteer: EventVolunteer { __data["eventVolunteer"] }
        var volunteerId: String { __data["volunteerId"] }
        var token: String { __data["token"] }
        var inviteMessage: String { __data["inviteMessage"] }

        /// ApproveJoinRequest.EventVolunteer
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
            .field("user", User.self),
            .field("event", Event.self),
            .field("department", Department?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ApproveJoinRequestMutation.Data.ApproveJoinRequest.EventVolunteer.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var volunteerId: String { __data["volunteerId"] }
          var user: User { __data["user"] }
          var event: Event { __data["event"] }
          var department: Department? { __data["department"] }

          /// ApproveJoinRequest.EventVolunteer.User
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
              ApproveJoinRequestMutation.Data.ApproveJoinRequest.EventVolunteer.User.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var firstName: String { __data["firstName"] }
            var lastName: String { __data["lastName"] }
          }

          /// ApproveJoinRequest.EventVolunteer.Event
          ///
          /// Parent Type: `Event`
          struct Event: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Event }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AssemblyOpsAPI.ID.self),
              .field("name", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              ApproveJoinRequestMutation.Data.ApproveJoinRequest.EventVolunteer.Event.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
          }

          /// ApproveJoinRequest.EventVolunteer.Department
          ///
          /// Parent Type: `Department`
          struct Department: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Department }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AssemblyOpsAPI.ID.self),
              .field("name", String.self),
              .field("departmentType", GraphQLEnum<AssemblyOpsAPI.DepartmentType>.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              ApproveJoinRequestMutation.Data.ApproveJoinRequest.EventVolunteer.Department.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
            var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType> { __data["departmentType"] }
          }
        }
      }
    }
  }

}