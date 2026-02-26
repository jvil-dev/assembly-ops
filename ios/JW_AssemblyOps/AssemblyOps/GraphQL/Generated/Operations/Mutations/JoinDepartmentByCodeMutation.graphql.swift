// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class JoinDepartmentByCodeMutation: GraphQLMutation {
    static let operationName: String = "JoinDepartmentByCode"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation JoinDepartmentByCode($input: JoinDepartmentByCodeInput!) { joinDepartmentByAccessCode(input: $input) { __typename eventVolunteer { __typename id } volunteerId token inviteMessage } }"#
      ))

    public var input: JoinDepartmentByCodeInput

    public init(input: JoinDepartmentByCodeInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("joinDepartmentByAccessCode", JoinDepartmentByAccessCode.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        JoinDepartmentByCodeMutation.Data.self
      ] }

      var joinDepartmentByAccessCode: JoinDepartmentByAccessCode { __data["joinDepartmentByAccessCode"] }

      /// JoinDepartmentByAccessCode
      ///
      /// Parent Type: `EventVolunteerCredentials`
      struct JoinDepartmentByAccessCode: AssemblyOpsAPI.SelectionSet {
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
          JoinDepartmentByCodeMutation.Data.JoinDepartmentByAccessCode.self
        ] }

        var eventVolunteer: EventVolunteer { __data["eventVolunteer"] }
        var volunteerId: String { __data["volunteerId"] }
        var token: String { __data["token"] }
        var inviteMessage: String { __data["inviteMessage"] }

        /// JoinDepartmentByAccessCode.EventVolunteer
        ///
        /// Parent Type: `EventVolunteer`
        struct EventVolunteer: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventVolunteer }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            JoinDepartmentByCodeMutation.Data.JoinDepartmentByAccessCode.EventVolunteer.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
        }
      }
    }
  }

}